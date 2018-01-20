#!/bin/bash

# Stop on error
set -e

#CCU2 firmware version
: ${CCU2_VERSION:="2.29.23"}

#CCU2 Serial Number
: ${CCU2_SERIAL:="ccu2_docker"}

#SSH Port
: ${CCU2_SSH_PORT:=2222}

#Rfd Port
: ${CCU2_RFD_PORT:=2001}

#hs485d Port
: ${CCU2_HS485D_PORT:=2002}

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
: ${DOCKER_ID:="litti/dccu2"}

#Run with docker swarm?
: ${DOCKER_MODE:="single"}

#Additional options for docker create service / docker run
: ${DOCKER_OPTIONS:=""}

##############################################
# No need to touch anything bellow this line #
##############################################

CWD=$(pwd)
BUILD_FOLDER=${CWD}/build
DOCKER_BUILD=docker_build
DOCKER_VOLUME_INTERNAL_PATH="/usr/local/"
DOCKER_NAME=ccu2

##########
# SCRIPT #
##########

mkdir -p ${BUILD_FOLDER}
cd ${BUILD_FOLDER}

echo "Installing Docker if needed"
if docker -v|grep -qvi version; then
  apt-get install -y docker.io
else
  echo "Docker not needed"
fi

echo
echo "Build Docker container in $DOCKER_BUILD"

# prepare some dirs
rm -rf $DOCKER_BUILD
mkdir $DOCKER_BUILD
mkdir -p $DOCKER_BUILD/etc/init.d
mkdir $DOCKER_BUILD/etc/config_templates
mkdir -p $DOCKER_BUILD/usr/sbin

#clear occu repo bugs
rm -rf ${CWD}/build/occu/HMserver/etc/init.d

# copy entrypoint
echo "creating entrypoint"
cp -l ${CWD}/Dockerfile ${CWD}/entrypoint.sh $DOCKER_BUILD

# lighttpd
echo "building lighttpd"
cp -l ${CWD}/build/occu/X86_32_Debian_Wheezy/packages/lighttpd/bin/* $DOCKER_BUILD/usr/sbin
cp -rl ${CWD}/build/occu/X86_32_Debian_Wheezy/packages/lighttpd/etc/lighttpd $DOCKER_BUILD/etc/lighttpd
cp -rl ${CWD}/build/occu/X86_32_Debian_Wheezy/packages/lighttpd/lib $DOCKER_BUILD/lib

# linuxbasis
echo "building linuxbasis"
cp -rl ${CWD}/build/occu/X86_32_Debian_Wheezy/packages-eQ-3/LinuxBasis/bin $DOCKER_BUILD/bin
cp -rl ${CWD}/build/occu/X86_32_Debian_Wheezy/packages-eQ-3/LinuxBasis/lib/* $DOCKER_BUILD/lib/

# hs485d - we love wired :-)
echo "building hs485d - we love wired :-)"
cp -rl ${CWD}/build/occu/X86_32_Debian_Wheezy/packages-eQ-3/HS485D/bin/* $DOCKER_BUILD/bin/
cp -rl ${CWD}/build/occu/X86_32_Debian_Wheezy/packages-eQ-3/HS485D/lib/* $DOCKER_BUILD/lib/

# rfd
echo "building rfd"
cp -rl ${CWD}/build/occu/X86_32_Debian_Wheezy/packages-eQ-3/RFD/bin/SetInterfaceClock $DOCKER_BUILD/bin/
cp -rl ${CWD}/build/occu/X86_32_Debian_Wheezy/packages-eQ-3/RFD/bin/avrprog $DOCKER_BUILD/bin/
cp -rl ${CWD}/build/occu/X86_32_Debian_Wheezy/packages-eQ-3/RFD/bin/crypttool $DOCKER_BUILD/bin/
cp -rl ${CWD}/build/occu/X86_32_Debian_Wheezy/packages-eQ-3/RFD/bin/rfd $DOCKER_BUILD/bin/
cp -rl ${CWD}/build/occu/X86_32_Debian_Wheezy/packages-eQ-3/RFD/etc/config_templates/* $DOCKER_BUILD/etc/config_templates/
cp -rl ${CWD}/build/occu/X86_32_Debian_Wheezy/packages-eQ-3/RFD/etc/crRFD.conf $DOCKER_BUILD/etc/
cp -rlf ${CWD}/build/occu/X86_32_Debian_Wheezy/packages-eQ-3/RFD/lib/* $DOCKER_BUILD/lib/

# HMIPServer
echo "building HMIPServer"
cp -rl ${CWD}/build/occu/HMserver/* $DOCKER_BUILD/

# Tante rega ;-)
echo "building ReGaHss ;-)"
cp -rl ${CWD}/build/occu/X86_32_Debian_Wheezy/packages-eQ-3/WebUI/bin/* $DOCKER_BUILD/bin/
cp -rl ${CWD}/build/occu/WebUI/bin/* $DOCKER_BUILD/bin/
cp -rl ${CWD}/build/occu/X86_32_Debian_Wheezy/packages-eQ-3/WebUI/etc/rega.conf $DOCKER_BUILD/etc/
cp -rlf ${CWD}/build/occu/X86_32_Debian_Wheezy/packages-eQ-3/WebUI/lib/* $DOCKER_BUILD/lib/
cp -rlP ${CWD}/build/occu/WebUI/www $DOCKER_BUILD/www

# image specific data
echo "building image specific data"
cp -rl ${CWD}/build/occu/firmware $DOCKER_BUILD/firmware/

# other data
echo "building other data"
cp -rlf ${CWD}/x86_32_debian_jessie/* $DOCKER_BUILD/

docker build -t $DOCKER_ID -t ${DOCKER_ID}:${CCU2_VERSION} $DOCKER_BUILD
if [[ ${DOCKER_ID} == */* ]]; then
  docker push $DOCKER_ID
  docker push ${DOCKER_ID}:${CCU2_VERSION}
fi

cd ${CWD}

#Install service that corrects permissions
echo
echo "Start ccu2 service"
cp -a enableCCUDevices.sh /usr/local/bin
cp ccu2.service /etc/systemd/system/ccu2.service
systemctl enable ccu2
service ccu2 restart

echo
echo "Stopping docker container - $DOCKER_ID"
#Remove container if already exits
if [ -f /etc/systemd/system/ccu2.service ] ; then
  #Legacy: before we had a service 
  service ccu2 stop
  rm /etc/systemd/system/ccu2.service
fi

docker service ls |grep -q $DOCKER_NAME && docker service rm $DOCKER_NAME
docker ps -a |grep -q $DOCKER_NAME && docker stop $DOCKER_NAME && docker rm -f $DOCKER_NAME

echo
if [ $DOCKER_MODE = swarm ] ; then
  echo "Starting as swarm service"
  docker service create --name $DOCKER_NAME \
  -p ${CCU2_WEBUI_PORT}:80 \
  -p ${CCU2_REGA_PORT}:8181 \
  -p ${CCU2_RFD_PORT}:2001 \
  -e PERSISTENT_DIR=${DOCKER_VOLUME_INTERNAL_PATH} \
  --mount type=bind,src=/dev,dst=/dev_org \
  --mount type=bind,src=/sys,dst=/sys_org \
  --mount type=bind,src=${DOCKER_CCU2_DATA},dst=${DOCKER_VOLUME_INTERNAL_PATH} \
  --hostname $DOCKER_NAME \
  --network $DOCKER_NAME \
  $DOCKER_OPTIONS \
  $DOCKER_ID
elif [ $DOCKER_MODE = single ] ; then
  echo "Starting container as plain docker"
  docker run --name $DOCKER_NAME \
  -p ${CCU2_SSH_PORT}:22 \
  -p ${CCU2_WEBUI_PORT}:80 \
  -p 1900:1900 \
  -p ${CCU2_RFD_PORT}:2001 \
  -p ${CCU2_HS485D_PORT}:2002 \
  -p ${CCU2_HMSERVER_PORT}:2010 \
  -p ${CCU2_REGA_PORT}:8181 \ \
  -p ${CCU2_VIRTDEV_PORT}:9292 \
  -e PERSISTENT_DIR=${DOCKER_VOLUME_INTERNAL_PATH} \
  -v ${DOCKER_CCU2_DATA}:${DOCKER_VOLUME_INTERNAL_PATH} \
  -v /dev/ttyUSB0:/dev/ttyUSB0 \
  --device=/dev/ttyUSB0:/dev_org/ttyUSB0:rwm \
  --hostname $DOCKER_NAME \
  -d --restart=always \
  $DOCKER_OPTIONS \
  $DOCKER_ID
else
  echo "No starting container: DOCKER_MODE = $DOCKER_MODE"
  exit 0
fi

echo
echo "Docker container started!"
echo "Docker data volume used: ${DOCKER_CCU2_DATA}"
if [[ ${DOCKER_CCU2_DATA} == */* ]]; then
  ln -sf ${DOCKER_CCU2_DATA}/etc/config/rfd.conf .
else
  echo "You can find its location with the command 'docker volume inspect ccu2_data'"
  docker volume inspect ${DOCKER_CCU2_DATA}
  ln -sf /var/lib/docker/volumes/${DOCKER_CCU2_DATA}/_data/etc/config/rfd.conf .
fi
