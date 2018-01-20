#!/bin/bash

# Stop on error
set -e

#SSH Port
: ${CCU2_SSH_PORT:=2222}

#Rfd Port
: ${CCU2_RFD_PORT:=2001}

#hs485d Port
: ${CCU2_HS485D_PORT:=2000}

#HM Server Port
: ${CCU2_HMSERVER_PORT:=2010}

#Rega Port
: ${CCU2_REGA_PORT:=8181}

#Webui Port
: ${CCU2_WEBUI_PORT:=8585}

#virtualdevices Port
: ${CCU2_VIRTDEV_PORT:=9292}

#Name of the docker volume where CCU2 data will persist
#It can be a local location as well such as a mounted NAS folder, cluster fs (glusterfs), etc.
: ${DOCKER_CCU2_DATA:="ccu2_data"}

#Docker ID is used to push built image to a docker repository (needed for docker swarm)
: ${DOCKER_ID:="litti/dccu2-x86_64"}

#Additional options for docker create service / docker run
: ${DOCKER_OPTIONS:=""}

##############################################
# No need to touch anything below this line  #
##############################################

DOCKER_VOLUME_INTERNAL_PATH="/usr/local/"
DOCKER_NAME=dccu2-x86_64

#######
# RUN #
#######

echo "Removing old plain docker instances"
docker ps -a |grep -q $DOCKER_NAME && docker stop $DOCKER_NAME && docker rm -f $DOCKER_NAME
echo "Starting container as plain docker"
docker run --name $DOCKER_NAME \
  -p ${CCU2_SSH_PORT}:22 \
  -p ${CCU2_WEBUI_PORT}:80 \
  -p 1900:1900 \
  -p ${CCU2_HS485D_PORT}:2000 \
  -p ${CCU2_RFD_PORT}:2001 \
  -p ${CCU2_HMSERVER_PORT}:2010 \
  -p ${CCU2_REGA_PORT}:8181 \
  -p 8700:8700 \
  -p 8701:8701 \
  -p ${CCU2_VIRTDEV_PORT}:9292 \
  -e PERSISTENT_DIR=${DOCKER_VOLUME_INTERNAL_PATH} \
  -v ${DOCKER_CCU2_DATA}:${DOCKER_VOLUME_INTERNAL_PATH} \
  --hostname $DOCKER_NAME \
  -d --restart=always \
  $DOCKER_OPTIONS \
  $DOCKER_ID
docker logs -f $(docker ps -a | grep "dccu2-x86_64" | awk '{print $1}')

echo
echo "Docker container started!"
echo "Docker data volume used: ${DOCKER_CCU2_DATA}"
