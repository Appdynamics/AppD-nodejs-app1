#!/bin/bash
#
#
# Docker helper script: build, push, run, bash, stop
# Maintainer: David Ryder
#
# Requires:
# jq - https://stedolan.github.io/jq/download/
#
CMDS_LIST=(${@:-"help"}) # All Commands as list
CMD_LIST_LEN=${#}

# if [ -d $DOCKER_TAG_NAME ]; then
#   echo "Docker image tag name envvar not set: DOCKER_TAG_NAME"
#   echo "export DOCKER_TAG_NAME=..."
#   exit 1
# fi
#DOCKER_TAG_NAME=${1:-"airflow-test1"}
#DOCKER_REPOSITORY_ACCOUNT=${2:-"NOTSET"}
#DOCKER_REPOSITORY_PWD=${3:-"NOTSET"}

# Check docker: Linux or Ubuntu snap
DOCKER_CMD=`which docker`
DOCKER_CMD=${DOCKER_CMD:-"/snap/bin/microk8s.docker"}
#echo "Using: "$DOCKER_CMD
if [ -d $DOCKER_CMD ]; then
    echo "Docker is missing: "$DOCKER_CMD
    exit 1
fi

# Check jq
JQ_CMD=`which jq`
if [ -d $JQ_CMD ]; then
    echo "jq is missing: "$JQ_CMD
    echo "Install jq: https://stedolan.github.io/jq/download/ "
    exit 1
fi

_dockerRun() {
  # Adds ports
  # Adds RW volume on host
  echo "Docker running $DOCKER_TAG_NAME"
  sleep 1
  docker ps
  $DOCKER_CMD run --rm --detach  \
            --name $DOCKER_TAG_NAME \
            --hostname $DOCKER_TAG_NAME \
            --volume /tmp/dock-$DOCKER_TAG_NAME:/$DOCKER_TAG_NAME:rw \
            -it                \
            $DOCKER_TAG_NAME
}

#   | jq --arg SEARCH_STR "$IMAGE_NAME" 'select(.Image==$SEARCH_STR)' \
_getDockerContainerId() {
  # Return first matching container id
  IMAGE_NAME=${1:-"Image Name Missing"}
  DOCKER_ID=`docker container ps --format '{{json .}}' \
    | jq --arg SEARCH_STR "$IMAGE_NAME" 'select(.Names | contains($SEARCH_STR))' \
    | jq -s '[.[] | {ID, Names, Image } ][0]' \
    | jq -r .ID`
    echo $DOCKER_ID
}

_getDockerContainerIds() {
  # Return list of container ids
  IMAGE_NAME=${1:-"Image Name Missing"}
  DOCKER_ID=`docker container ps --format '{{json .}}' \
    | jq --arg SEARCH_STR "$IMAGE_NAME" 'select(.Names | contains($SEARCH_STR))' \
    | jq -s '[.[] | {ID, Names, Image } ]'`
    echo $DOCKER_ID
}

_dockerStopContainers() {
  DOCKER_TAG_NAME=$1
  CONTAINER_ID_LIST=`_getDockerContainerIds $DOCKER_TAG_NAME`
  echo "[]$CONTAINER_ID_LIST[]"
  echo $CONTAINER_ID_LIST | jq -c '.[]' | while read ITEM; do
    ID=`echo $ITEM | jq -r .ID`
    NAME=`echo $ITEM | jq -r .Names`
    echo "Stopping $ID $NAME"
    docker stop ${ID} &
  done
}

_dockerWaitForContainersToStop() {
  DOCKER_TAG_NAME=$1
  CONTAINER_ID_LIST=`_getDockerContainerIds $DOCKER_TAG_NAME`
  while [ "$CONTAINER_ID_LIST" != "[]" ];
  do
      RUNNING_CONTAINERS=`echo '[ { "ID": "14c97bf487c8", "Names": "test-app1", "Image": "test-app1" }, { "ID": "f6182c9a20c5", "Names": "backend-app", "Image": "backend-app" } ]' | jq '.[] | .Names'`
      echo "Waiting for containers to stop: $RUNNING_CONTAINERS"
      sleep 1
      CONTAINER_ID_LIST=`_getDockerContainerIds $DOCKER_TAG_NAME`
  done
}

_getDockerContainerIdImage() {
  IMAGE_NAME=${1:-"Image Name Missing"}
  DOCKER_ID=`docker container ps --format '{{json .}}' \
    | jq --arg SEARCH_STR "$IMAGE_NAME" 'select(.Image | contains($SEARCH_STR))' \
    | jq -s '[.[] | {ID, Names, Image } ][0]' \
    | jq -r .ID`
    echo $DOCKER_ID
}

_getDockerImageId() {
  REPOSITORY_NAME=${1:-"Repository Name Missing"}
  DOCKER_ID=`docker images --format '{{json .}}' \
    | jq --arg SEARCH_STR "$REPOSITORY_NAME" 'select(.Repository==$SEARCH_STR )' \
    | jq -s '[.[] | {Repository, ID} ][0]' \
    | jq -r .ID`
  echo $DOCKER_ID
}

_dockerPrune() {
  $DOCKER_CMD system prune -f
}

_dockerBuild() {
  echo "Building image: "$DOCKER_TAG_NAME
  $DOCKER_CMD build -t $DOCKER_TAG_NAME .
}

_dockerPush() {
  if [ "$DOCKER_REPOSITORY_PWD" != "" ]; then
    $DOCKER_CMD login -u $DOCKER_REPOSITORY_ACCOUNT -p $DOCKER_REPOSITORY_PWD
  fi
  $DOCKER_CMD tag $DOCKER_TAG_NAME  $DOCKER_REPOSITORY_TAG_NAME
  $DOCKER_CMD push $DOCKER_REPOSITORY_TAG_NAME
}

_dockerWaitUntilRunning() {
  CID="null"
  while [ "$CID" == "null" ];
  do
      echo "Waiting for container to start: $DOCKER_TAG_NAME $CID"
      sleep 1
      CID=$(_getDockerContainerId $DOCKER_TAG_NAME)
  done
  echo "Container Started: $DOCKER_TAG_NAME $CID"
}

_dockerWaitUntilStopped() {
  DOCKER_TAG_NAME=$1
  CID=$(_getDockerContainerId ${DOCKER_TAG_NAME})
  while [ "$CID" != "null" ];
  do
      echo "Waiting for container to stop: $DOCKER_TAG_NAME $CID"
      sleep 2
      CID=$(_getDockerContainerId $DOCKER_TAG_NAME)
  done
  echo "Container Stopped: $DOCKER_TAG_NAME $CID"
}

_dockerBash() {
  CID=$(_getDockerContainerIdImage ${DOCKER_TAG_NAME})
  echo "Container ID $CID for ${DOCKER_TAG_NAME}"
  $DOCKER_CMD exec -it $CID /bin/bash
}

_dockerStop() {
  DOCKER_TAG_NAME=$1
  CONTAINER_ID=`_getDockerContainerId $DOCKER_TAG_NAME`
  if [ "$CONTAINER_ID" != "" ]; then
    echo "Stop ${DOCKER_TAG_NAME} ${CONTAINER_ID}"
    docker stop ${CONTAINER_ID} &
    sleep 5 # some time for container to stop
  else
    echo "Container ${DOCKER_TAG_NAME} is not running"
  fi
}



_dockerDeleteImage() {
  IMAGE_ID=`_getDockerImageId ${DOCKER_TAG_NAME}`
  echo ${DOCKER_TAG_NAME} $IMAGE_ID
  if [ "$IMAGE_ID" != "" ]; then
    echo "Deleting image ${DOCKER_TAG_NAME} ${IMAGE_ID}"
    docker rmi ${IMAGE_ID}
  else
    echo "Image ${DOCKER_TAG_NAME} not found"
  fi
}

_runCommand() {
  CMD=${1:-"help"}
  #echo "Running [$CMD]"
  if [ $CMD == "build" ]; then
    _dockerBuild
  elif [ $CMD == "prune" ]; then
    _dockerPrune
  elif [ $CMD == "push" ]; then
    DOCKER_REPOSITORY_TAG_NAME=$DOCKER_REPOSITORY_ACCOUNT/$DOCKER_TAG_NAME
    _dockerPush
  elif [ $CMD == "run" ]; then
    i=$(( i + 1 )); DOCKER_TAG_NAME=${CMDS_LIST[$i]}
    _dockerRun
    _dockerWaitUntilRunning
  elif [ $CMD == "bash" ]; then
    i=$(( i + 1 )); DOCKER_TAG_NAME=${CMDS_LIST[$i]}
    _dockerBash
  elif [ $CMD == "stop" ]; then
    i=$(( i + 1 )); DOCKER_TAG_NAME=${CMDS_LIST[$i]}
    _dockerStop
    _dockerWaitUntilStopped
  elif [ $CMD == "stop-all" ]; then
    docker stop $(docker ps -aq)
  elif [ $CMD == "delete" ]; then
    _dockerDeleteImage
  elif [ $CMD == "sync" ]; then
    # Sync files to build this container
    rsync -vraH ../Common/ Common
  elif [ $CMD == "pass" ]; then
    echo ""
  else
    echo "Commands: build | build-push | run | bash | stop "
    exit 1
  fi
}

if [ $1 != "pass" ]; then
for (( i=0; i<$CMD_LIST_LEN; i++ )); do
  CMD="${CMDS_LIST[$i]}"
  echo "Running Command: $i $CMD"
  _runCommand $CMD
done
fi
