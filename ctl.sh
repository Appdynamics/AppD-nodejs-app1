#!/bin/bash
#
#
CMD=${1:-"help"}
CMD_ARGS_LEN=${#}
CMDS_LIST=${@:-"help"} # All Commands



# Check docker: Linux or Ubuntu snap
DOCKER_CMD=`which docker`
DOCKER_CMD=${DOCKER_CMD:-"/snap/bin/microk8s.docker"}
echo "Using: $DOCKER_CMD"
if [ -d $DOCKER_CMD ]; then
    echo "Docker is missing: "$DOCKER_CMD
    exit 1
fi

# Check docker: Linux or Ubuntu snap
KUBECTL_CMD=`which kubectl`
KUBECTL_CMD=${KUBECTL_CMD:-"/snap/bin/microk8s.kubectl"}
echo "Using: $KUBECTL_CMD"
if [ -d $KUBECTL_CMD ]; then
    echo "Kubectl is missing: ($KUBECTL_CMD)"
fi

# envvars
if [ -f envvars.sh ]; then
  . envvars.sh
else
  echo "Warning: envvars.sh not found"
fi

_config() {
  echo ""
}

CONTAINER_NAME="node-test-app1"
DOCKER_TAG_NAME="nodejs1"
DOCKER_REPOSITORY_ACCOUNT="localhost:5555"
DOCKER_REPOSITORY_TAG_NAME="$DOCKER_REPOSITORY_ACCOUNT/$DOCKER_TAG_NAME"
APPD_CONTROLLER_PROTOCOL="https"
CERT_PEM_FILE=$APPDYNAMICS_CONTROLLER_HOST_NAME"-cert.pem"
CERT_PEM_FILE="appd-controller-cert.pem"
KEYSTORE_FILE=$APPDYNAMICS_CONTROLLER_HOST_NAME"-cacerts.jks"
KEYSTORE_PASSWORD="CHANGEME"

_validateEnvironmentVars() {
  echo "Validating environment variables for $1"
  shift 1
  VAR_LIST=("$@") # rebuild using all args
  #echo $VAR_LIST
  for i in "${VAR_LIST[@]}"; do
    echo "  $i=${!i}"
    if [ -z "${!i}" ] || [[ "${!i}" == REQUIRED_* ]]; then
       echo "Please set the Environment variable: $i"; ERROR="1";
    fi
  done
  [ "$ERROR" == "1" ] && { echo "Exiting"; exit 1; }
}


_makeConfigMap_appdynamics_secrets() {
  OUTPUT_FILE_NAME=$1
  _validateEnvironmentVars "AppDynamics Controller $OUTPUT_FILE_NAME"  \
                           "APPDYNAMICS_AGENT_ACCOUNT_ACCESS_KEY" "APPDYNAMICS_AGENT_ACCOUNT_NAME"

# Note indentation is critical between cat and EOF
cat << EOF > $OUTPUT_FILE_NAME
# Environment varibales requried for ADCAP approvals - Secret Base64 Encoded
---
apiVersion: v1
kind: Secret
metadata:
  name: appdynamics-secrets
type: Opaque
data:
  accesskey: "`echo -n $APPDYNAMICS_AGENT_ACCOUNT_ACCESS_KEY | base64`"
  accountname: "`echo -n $APPDYNAMICS_AGENT_ACCOUNT_NAME | base64`"
EOF
#####
}


_makeAppD_makeConfigMap_appdynamics_common() {
  OUTPUT_FILE_NAME=$1
  _validateEnvironmentVars "AppDynamics Controller $OUTPUT_FILE_NAME"  \
                           "APPDYNAMICS_AGENT_APPLICATION_NAME" "APPDYNAMICS_CONTROLLER_HOST_NAME" \
                           "APPDYNAMICS_CONTROLLER_PORT" "APPDYNAMICS_CONTROLLER_SSL_ENABLED"

# Note indentation is critical between cat and EOF
cat << EOF > $OUTPUT_FILE_NAME
# Environment variables common across all AppDynamics Agents -  Clear Text
---
apiVersion: v1
kind: ConfigMap
metadata:
  creationTimestamp: null
  name: appdynamics-common
data:
  APPD_DIR: "/appdynamics"
  APPD_ES_HOST: ""
  APPD_ES_PORT: "9080"
  APPD_ES_SSL: "false"
  APPD_EVENT_ACCOUNT_NAME: "XXX"
  APPDYNAMICS_AGENT_APPLICATION_NAME: "$APPDYNAMICS_AGENT_APPLICATION_NAME"
  APPDYNAMICS_CONTROLLER_HOST_NAME: "$APPDYNAMICS_CONTROLLER_HOST_NAME"
  APPDYNAMICS_CONTROLLER_PORT: "$APPDYNAMICS_CONTROLLER_PORT"
  APPDYNAMICS_CONTROLLER_SSL_ENABLED: "$APPDYNAMICS_CONTROLLER_SSL_ENABLED"
  APPD_JAVAAGENT: "-javaagent:/opt/appdynamics-agents/java/javaagent.jar"
  APPDYNAMICS_NETVIZ_AGENT_PORT: "3892"
EOF
#####
}

_docker_get_container_id() {
  CONTAINER_NAME=$1
  echo `docker inspect --format='{{ .Id }}' $CONTAINER_NAME`
}

# Execute command
#for CMD in ${CMDS_LIST}; do
case "$CMD" in
  appd-cluster-agent)
    $KUBECTL_CMD delete configmap appdynamics-common
    $KUBECTL_CMD delete secret appdynamics-secrets
    $KUBECTL_CMD delete configmap appd-start-js
    $KUBECTL_CMD delete configmap appd-start-sh
    $KUBECTL_CMD delete configmap appd-controller-cert

    $KUBECTL_CMD create -f appdynamics-common-configmap.yaml
    $KUBECTL_CMD create -f appdynamics-secrets.yaml
    $KUBECTL_CMD create configmap appd-start-js --from-file=appd-start.js
    $KUBECTL_CMD create configmap appd-start-sh --from-file=appd-start.sh
    $KUBECTL_CMD create configmap appd-controller-cert --from-file=$CERT_PEM_FILE

    $KUBECTL_CMD get configmaps appdynamics-common -o yaml
    $KUBECTL_CMD get secret appdynamics-secrets -o yaml
    $KUBECTL_CMD get configmaps appd-start-js -o yaml
    $KUBECTL_CMD get configmaps appd-start-sh -o yaml
    $KUBECTL_CMD get configmaps appd-controller-cert-o yaml

    $KUBECTL_CMD get configmaps
    $KUBECTL_CMD get secrets
    ;;
  configure)
    # Downloads required file before bulding containers
    DOWNLOADS_DIR="downloads/"
    mkdir -p $DOWNLOADS_DIR
    curl https://raw.githubusercontent.com/creationix/nvm/v0.33.11/install.sh -o $DOWNLOADS_DIR/nvm-v0-33-11-install.sh
    ;;
  build) # Expects Argument APP_ID
    DOCKER_TAG_NAME=${2:-"DOCKER_TAG_MISSING"}
    DOCKERFILE="./$DOCKERFILES_DIR/$DOCKER_TAG_NAME.Dockerfile"
    echo "Building $DOCKERFILE Tag: $DOCKER_TAG_NAME"
    $DOCKER_CMD build \
      --build-arg USER=$USER \
      --build-arg HOME_DIR=$HOME_DIR \
      -t $DOCKER_TAG_NAME \
      --file $DOCKERFILE .
  ;;
  build-orig)
    docker build -t $DOCKER_TAG_NAME .
  ;;
  docker-install)
    _DockerCE_Install
    ;;
  docker-delete-all)
    docker rmi $(docker images -q) -f
    docker system prune --all --force
    ;;
  push)
    docker tag  $DOCKER_TAG_NAME  $DOCKER_REPOSITORY_TAG_NAME
    docker push $DOCKER_REPOSITORY_TAG_NAME
    ;;
  docker-start)
    DOCKER_TAG_NAME=${2:-"DOCKER TAG MISSING"}
    docker run -d --rm --name $DOCKER_TAG_NAME\
      -p $APP_LISTEN_PORT:$APP_LISTEN_PORT \
      -e APP_LISTEN_PORT=$APP_LISTEN_PORT \
      -e APPDYNAMICS_CONTROLLER_HOST_NAME=$APPDYNAMICS_CONTROLLER_HOST_NAME \
      -e APPDYNAMICS_CONTROLLER_PORT=$APPDYNAMICS_CONTROLLER_PORT \
      -e APPDYNAMICS_CONTROLLER_SSL_ENABLED=$APPDYNAMICS_CONTROLLER_SSL_ENABLED \
      -e APPDYNAMICS_CONTROLLER_CERTIFICATE_FILE=$APPDYNAMICS_CONTROLLER_CERTIFICATE_FILE \
      -e APPDYNAMICS_AGENT_ACCOUNT_NAME=$APPDYNAMICS_AGENT_ACCOUNT_NAME \
      -e APPDYNAMICS_AGENT_ACCOUNT_ACCESS_KEY=$APPDYNAMICS_AGENT_ACCOUNT_ACCESS_KEY \
      -e APPDYNAMICS_AGENT_APPLICATION_NAME=$APPDYNAMICS_AGENT_APPLICATION_NAME \
      -e APPDYNAMICS_AGENT_TIER_NAME=$APPDYNAMICS_AGENT_TIER_NAME \
      -e APPDYNAMICS_AGENT_NODE_NAME=$APPDYNAMICS_AGENT_NODE_NAME \
    $DOCKER_TAG_NAME
    ;;
  docker-stop)
    ID=$(_docker_get_container_id $CONTAINER_NAME )
    echo "Stopping $CONTAINER_NAME $ID"
    docker stop $ID
    ;;
  docker-bash)
    CONTAINER_NAME=${2:-"DOCKER CONTAINER NAME MISSING"}
    ID=$(_docker_get_container_id $CONTAINER_NAME )
    docker exec -it $ID bash
    ;;
  start)
    $KUBECTL_CMD create -f app2.yaml
    ;;
  stop)
    $KUBECTL_CMD delete -f app2.yaml
    ;;
  port-forward)
    microk8s.kubectl port-forward --address 127.0.0.1 --namespace default deployment/app2 8081:8081
    ;;
  load-gen)
    count=5000
    interval=5
    HOST="http://localhost"
    PORT="8081"
    URI="/"
    for i in $(seq $count )
    do
      now=`date `
      echo "$started - $now - Iteration "$i
      curl $HOST:$PORT$URI
    	sleep $interval
    done
    ;;
  create-controller-ca-cert)
    CONTROLLER_STATUS_URL="$APPD_CONTROLLER_PROTOCOL://$APPDYNAMICS_CONTROLLER_HOST_NAME:$APPDYNAMICS_CONTROLLER_PORT/controller/rest/serverstatus"
    curl -v $CONTROLLER_STATUS_URL
    if [ $? -ne 0 ]; then
        echo "Failed to connect to: $CONTROLLER_STATUS_URL"
        exit 0
    else
        echo "Connection succeeded: $CONTROLLER_STATUS_URL"
    fi

    echo | \
      openssl s_client -showcerts -connect $APPDYNAMICS_CONTROLLER_HOST_NAME:$APPDYNAMICS_CONTROLLER_PORT 2>&1 | \
      sed -ne '/-BEGIN CERTIFICATE-/,/-END CERTIFICATE-/p' > $CERT_PEM_FILE


    #keytool -import -alias rootCA -file $CERT_PEM_FILE -keystore $KEYSTORE_FILE -storepass $KEYSTORE_PASSWORD
    echo "Created $CERT_PEM_FILE"
    #echo "Created $KEYSTORE_FILE with password $KEYSTORE_PASSWORD"
    ;;
  k8s-install)
    _MicroK8s_Install
    ;;
  k8s-start)
    _MicroK8s_Start
    ;;
  pods-create)
    # Create the namespace: test
    for K8S_RESOURCE in "${ALL_NS_LIST[@]}"; do
      $KUBECTL_CMD create -f pods/$K8S_RESOURCE.yaml
    done
    # Create the pods
    for K8S_RESOURCE in "${ALL_RUN_LIST[@]}"; do
      $KUBECTL_CMD create -f pods/$K8S_RESOURCE.yaml
    done
    ;;
  pods-delete)
    # Delete the pods
    for K8S_RESOURCE in "${ALL_RUN_LIST[@]}"; do
      $KUBECTL_CMD delete -f pods/$K8S_RESOURCE.yaml
    done
    # Delete the namespace
    for K8S_RESOURCE in "${ALL_NS_LIST[@]}"; do
      $KUBECTL_CMD delete -f pods/$K8S_RESOURCE.yaml
    done
    ;;
  k8s-delete-all)
    $KUBECTL_CMD -n default delete pod,svc --all
    ;;
  k8s-log-dns)
    $KUBECTL_CMD logs --follow -n kube-system --selector 'k8s-app=kube-dns'
    ;;
  k8s-restart)
    sudo snap disable microk8s
    sudo snap enable microk8s
    ;;
  appd-create-cluster-agent)
    _AppDynamics_Install_ClusterAgent "create"
    ;;
  appd-replace-cluster-agent)
    _AppDynamics_Install_ClusterAgent "replace"
    ;;
  appd-delete-cluster-agent)
    _AppDynamics_Delete_ClusterAgent
    ;;
  services)
    $KUBECTL_CMD get services --all-namespaces -o wide
    ;;
  ns)
    $KUBECTL_CMD get all --all-namespaces
    ;;
  k8s-metrics)
    microk8s.enable get --raw /apis/metrics.k8s.io/v1beta1/pods
    ;;
  dashboard-token)
    token=$(microk8s.kubectl -n kube-system get secret | grep default-token | cut -d " " -f1)
    microk8s.kubectl -n kube-system describe secret $token
    # kc proxy
    # ssh -N -L 8888:localhost:8001 r-apps
    # http://localhost:8888/api/v1/namespaces/kube-system/services/https:kubernetes-dashboard:/proxy/#!/login
    ;;
  group-remove)
    # Testing
    sudo gpasswd -d $USER microk8s
    sudo gpasswd -d $USER docker
    ;;
  logs)
    kc logs -n airflow $POD -f
    ;;
  test)
    echo "Test"
    ;;
  help)
    echo "create-controller-ca-cert"
    ;;
  *)
    echo "Not Found " "$@"
    ;;
esac
#done
