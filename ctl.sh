#!/bin/bash
#
#
CMD=${1:-"help"}
CMD_ARGS_LEN=${#}
CMDS_LIST=${@:-"help"} # All Commands

. docker-ctl.sh pass

# Check docker: Linux or Ubuntu snap
DOCKER_CMD=`which docker`
DOCKER_CMD=${DOCKER_CMD:-"/snap/bin/microk8s.docker"}
#echo "Using: $DOCKER_CMD"
if [ -d $DOCKER_CMD ]; then
    echo "Docker is missing: "$DOCKER_CMD
    exit 1
fi

# Check docker: Linux or Ubuntu snap
KUBECTL_CMD=`which kubectl`
KUBECTL_CMD=${KUBECTL_CMD:-"/snap/bin/microk8s.kubectl"}
#echo "Using: $KUBECTL_CMD"
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

# Execute command
#for CMD in ${CMDS_LIST}; do
case "$CMD" in
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
  build-all)
  BUILD_LIST=("test-app1" "test-app2" "test-app3" "test-app4" "test-app-backend")
  for APP_NAME in "${BUILD_LIST[@]}"; do
    ./ctl.sh build $APP_NAME
  done
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
  run)
    DOCKER_TAG_NAME=${2:-""}
    DOCKER_RUN_DETACHED=${3:-"--detach"}
    _validateEnvironmentVars "docker run" "DOCKER_TAG_NAME" "DOCKER_RUN_DETACHED" "APP_LISTEN_PORT" "APP_LATENCY" \
      "APPDYNAMICS_CONTROLLER_HOST_NAME" "APPDYNAMICS_CONTROLLER_PORT" "APPDYNAMICS_CONTROLLER_SSL_ENABLED" \
      "APPDYNAMICS_AGENT_ACCOUNT_NAME" "APPDYNAMICS_AGENT_ACCOUNT_ACCESS_KEY" \
      "APPDYNAMICS_AGENT_APPLICATION_NAME" "APPDYNAMICS_AGENT_TIER_NAME" "APPDYNAMICS_AGENT_NODE_NAME"
    if [ $DOCKER_TAG_NAME == "backend-app" ]; then
        APP_LISTEN_PORT="5646"
        APPDYNAMICS_AGENT_TIER_NAME="DDR_TIER_T1_B1"
        APPDYNAMICS_AGENT_NODE_NAME="DDR_NODE_N1_B1"
    elif [ $DOCKER_TAG_NAME == "postgres" ]; then
        EXTRA_ARGS="-p 5432:5432"
    elif [ $DOCKER_TAG_NAME$ID == "mysql0" ]; then
        EXTRA_ARGS="-p 3306:3306"
    fi
    docker network create -d bridge $DOCKER_NETWORK_NAME > /dev/null 2>&1
    docker run $DOCKER_RUN_DETACHED --rm --name $DOCKER_TAG_NAME\
      -p $APP_LISTEN_PORT:$APP_LISTEN_PORT \
      --network $DOCKER_NETWORK_NAME \
      -e APP_LISTEN_PORT=$APP_LISTEN_PORT \
      -e APP_LATENCY=$APP_LATENCY \
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
      _dockerWaitUntilRunning $DOCKER_TAG_NAME
    ;;
  stop)
    CONTAINER_NAME=${2:-"DOCKER CONTAINER NAME MISSING"}
    echo "Stopping $CONTAINER_NAME $ID"
    _dockerStop $CONTAINER_NAME
    _dockerWaitUntilStopped $CONTAINER_NAME
    ;;
  restart)
    DOCKER_TAG_NAME=${2:-""}
    ./ctl.sh stop $DOCKER_TAG_NAME
    ./ctl.sh run $DOCKER_TAG_NAME
    ;;
  test-curl)
    curl -X PUT \
      -H "Content-Type: application/json" \
      -H "singularityheader: appId=20&ctrlguid=1604867626&acctguid=7950e532-228a-4419-8dfc-b14ae6c7072c&ts=1604869901488&btid=209&guid=a46fc4bb-8788-4b43-8a4e-3eaba75a4994&exitguid=1&unresolvedexitid=11&cidfrom=58&etypeorder=HTTP&cidto=60" \
      -d '{"id":12294}' \
      http://localhost:5646/api/test
    ;;
  bash)
    CONTAINER_NAME=${2:-"DOCKER CONTAINER NAME MISSING"}
    ID=$(_getDockerContainerId $CONTAINER_NAME )
    docker exec -it $ID bash
    ;;
  port-forward)
    microk8s.kubectl port-forward --address 127.0.0.1 --namespace default deployment/app2 8081:8081
    ;;
  load-gen1)
    count=5000
    interval=${2:-"5"}
    HOST="http://localhost"
    PORT="$APP_LISTEN_PORT"
    URI="/"
    for i in $(seq $count )
    do
      now=`date `
      echo "$started - $now - Iteration "$i
      curl $HOST:$PORT$URI
    	sleep $interval
    done
    ;;
  load-gen-params)
    count=5000
    interval=5
    HOST="http://localhost"
    PORT="$APP_LISTEN_PORT"
    PARAM_P1=1100
    PARAM_P2=1
    PARAM_P3=2
    URI="/slow2?p1=$PARAM_P1&p2=$PARAM_P2&p3=$PARAM_P3"
    for i in $(seq $count )
    do
      now=`date `
      echo "$started - $now - Iteration "$i
      curl -o /dev/null -s -w "%{time_total}\n" $HOST:$PORT$URI
    	sleep $interval
    done
    ;;
    load-gen-single)
      DURATION_SEC=${2:-"3600"}
      INTERVAL_SEC=${3:-"60"}
      URI=${4:-"/"}
      START_TIME=$(date +%s)
      END_TIME=$(( START_TIME + DURATION_SEC ))
      HOST="http://localhost"
      PORT="$APP_LISTEN_PORT"
      while (true); do
        now=`date `
        echo "$started - $now - Iteration "$i
        curl -o /dev/null -s -w "%{time_total}\n" $HOST:$PORT$URI
        TIME_NOW=$(date +%s)
        if [ "$TIME_NOW" -gt "$END_TIME" ]; then
          echo "Stopping $(date)"
          break;
        else
          sleep $INTERVAL_SEC
        fi
      done
      ;;
    load-gen-concurrent)
      DURATION_SEC=${2:-"3600"}
      INTERVAL_SEC=${3:-"60"}
      CONCURRENCY_N=${4:-"5"}
      URI=${5:-"/"}
      START_TIME=$(date +%s)
      END_TIME=$(( START_TIME + DURATION_SEC ))
      HOST="http://localhost"
      PORT="$APP_LISTEN_PORT"
      N_REQUESTS=0
      while (true); do
        now=`date `
        echo "$started - $now - Iteration $i Requests $N_REQUESTS Concurrency $CONCURRENCY_N - $URI"
        for ii in $(seq 1 $CONCURRENCY_N); do
          echo $ii $(curl -o /dev/null -s -w "%{time_total}\n" $HOST:$PORT$URI) &
          N_REQUESTS=$(( N_REQUESTS + 1))
        done
        TIME_NOW=$(date +%s)
        if [ "$TIME_NOW" -gt "$END_TIME" ]; then
          echo "Stopping $(date)"
          break;
        else
          sleep $INTERVAL_SEC
        fi
      done
      ;;
  load-gen-sequence)
      DURATION_SEC=${2:-"300"}
      echo "DURATION_SEC $DURATION_SEC"
      while (true); do
        ./ctl.sh load-gen-single        $DURATION_SEC 5
        ./ctl.sh load-gen-concurrent    $DURATION_SEC 30
        sleep $DURATION_SEC # No load
      done
      ;;
  load-gen-random)
    INTERATIONS_N=999999
    INTERVAL_SEC=5
    DURATION_SEC=7200

    HOST="localhost"
    PORT="$APP_LISTEN_PORT"
    API="/"

    URL_LIST=("/" "/date" "/slow" "/echo?name=test")
    URL_LIST_LEN=${#URL_LIST[@]}

    echo "Starting loadgen"
    START_TIME=$(date +%s)
    END_TIME=$(( START_TIME + DURATION_SEC ))
    for i in $(seq $INTERATIONS_N )
    do
      URL_N=$(( RANDOM % URL_LIST_LEN ))
      API="${URL_LIST[$URL_N]}"
      echo "Calling: $HOST:$PORT$API $i"
      curl -G $HOST:$PORT$API
      TIME_NOW=$(date +%s)
      if [ "$TIME_NOW" -gt "$END_TIME" ]; then
        echo "Stopping"
        break;
      else
        sleep $INTERVAL_SEC
      fi
    done
    echo "Stopping loadgen"
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
