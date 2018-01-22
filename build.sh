#!/bin/bash

# Stop on error
set -e

#CCU2 firmware version
: ${CCU2_VERSION:="2.31.25.20180119"}

#Docker ID is used to push built image to a docker repository (needed for docker swarm)
: ${DOCKER_ID:="litti/dccu2-x86_64"}

#############################################
# No need to touch anything below this line #
#############################################

RDIR=${PWD}
BUILD_FOLDER=$RDIR/build
DOCKER_BUILD=docker_build
DOCKER_VOLUME_INTERNAL_PATH="/usr/local/"
DOCKER_NAME=dccu2-x86_64

. ./prepare.sh

if [ "$1" == "dev" ]; then
  docker build -t $DOCKER_ID:dev $DOCKER_BUILD

  echo "#!/bin/sh" >push.sh
  echo "docker push $DOCKER_ID:dev" >>push.sh
  chmod 755 push.sh
else
  docker build -t $DOCKER_ID -t $DOCKER_ID:$CCU2_VERSION $DOCKER_BUILD

  echo "#!/bin/sh" >push.sh
  echo "docker push $DOCKER_ID" >>push.sh
  echo "docker push ${DOCKER_ID}:${CCU2_VERSION}" >>push.sh
  chmod 755 push.sh
fi