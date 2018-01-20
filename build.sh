#!/bin/bash

# Stop on error
set -e

#CCU2 firmware version
: ${CCU2_VERSION:="2.31.25.20180119"}

#CCU2 Serial Number
: ${CCU2_SERIAL:="ccu2_docker"}

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

#########
# BUILD #
#########

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
rm -rf $RDIR/dependencies/occu/HMserver/etc/init.d

# copy entrypoint
echo "creating entrypoint"
echo "$pwd"
cp -l $RDIR/Dockerfile $RDIR/entrypoint.sh $DOCKER_BUILD

#get dependency occu
if [ ! -d "$RDIR/dependencies/occu" ]; then
	echo "Cloning OCCU-Repository"
	mkdir -p $RDIR/dependencies/occu
	git clone https://github.com/eq-3/occu $RDIR/dependencies/occu/
else
	echo "OCCU-Repository already there, just pulling changes"
	git -C $RDIR/dependencies/occu pull
fi

# lighttpd
echo "building lighttpd"
cp -l $RDIR/dependencies/occu/X86_32_Debian_Wheezy/packages/lighttpd/bin/* $DOCKER_BUILD/usr/sbin
cp -rl $RDIR/dependencies/occu/X86_32_Debian_Wheezy/packages/lighttpd/etc/lighttpd $DOCKER_BUILD/etc/lighttpd
cp -rl $RDIR/dependencies/occu/X86_32_Debian_Wheezy/packages/lighttpd/lib $DOCKER_BUILD/lib

# linuxbasis
echo "building linuxbasis"
cp -rl $RDIR/dependencies/occu/X86_32_Debian_Wheezy/packages-eQ-3/LinuxBasis/bin $DOCKER_BUILD/bin
cp -rl $RDIR/dependencies/occu/X86_32_Debian_Wheezy/packages-eQ-3/LinuxBasis/lib/* $DOCKER_BUILD/lib/

# hs485d - we love wired :-)
echo "building hs485d - we love wired :-)"
cp -rl $RDIR/dependencies/occu/X86_32_Debian_Wheezy/packages-eQ-3/HS485D/bin/* $DOCKER_BUILD/bin/
cp -rl $RDIR/dependencies/occu/X86_32_Debian_Wheezy/packages-eQ-3/HS485D/lib/* $DOCKER_BUILD/lib/

# rfd
echo "building rfd"
cp -rl $RDIR/dependencies/occu/X86_32_Debian_Wheezy/packages-eQ-3/RFD/bin/SetInterfaceClock $DOCKER_BUILD/bin/
cp -rl $RDIR/dependencies/occu/X86_32_Debian_Wheezy/packages-eQ-3/RFD/bin/avrprog $DOCKER_BUILD/bin/
cp -rl $RDIR/dependencies/occu/X86_32_Debian_Wheezy/packages-eQ-3/RFD/bin/crypttool $DOCKER_BUILD/bin/
cp -rl $RDIR/dependencies/occu/X86_32_Debian_Wheezy/packages-eQ-3/RFD/bin/rfd $DOCKER_BUILD/bin/
cp -rl $RDIR/dependencies/occu/X86_32_Debian_Wheezy/packages-eQ-3/RFD/etc/config_templates/* $DOCKER_BUILD/etc/config_templates/
cp -rl $RDIR/dependencies/occu/X86_32_Debian_Wheezy/packages-eQ-3/RFD/etc/crRFD.conf $DOCKER_BUILD/etc/
cp -rlf $RDIR/dependencies/occu/X86_32_Debian_Wheezy/packages-eQ-3/RFD/lib/* $DOCKER_BUILD/lib/

# HMIPServer
echo "building HMIPServer"
cp -rl $RDIR/dependencies/occu/HMserver/* $DOCKER_BUILD/
rm -rf $DOCKER_BUILD/opt/HMServer/HMServer.jar

# Tante rega ;-)
echo "building ReGaHss ;-)"
cp -rl $RDIR/dependencies/occu/X86_32_Debian_Wheezy/packages-eQ-3/WebUI/bin/* $DOCKER_BUILD/bin/
cp -rl $RDIR/dependencies/occu/WebUI/bin/* $DOCKER_BUILD/bin/
cp -rl $RDIR/dependencies/occu/X86_32_Debian_Wheezy/packages-eQ-3/WebUI/etc/rega.conf $DOCKER_BUILD/etc/
cp -rlf $RDIR/dependencies/occu/X86_32_Debian_Wheezy/packages-eQ-3/WebUI/lib/* $DOCKER_BUILD/lib/
cp -rlP $RDIR/dependencies/occu/WebUI/www $DOCKER_BUILD/www

#version info
sed -i 's/WEBUI_VERSION = ".*";/WEBUI_VERSION = "'$CCU2_VERSION'";/' $DOCKER_BUILD/www/rega/pages/index.htm
sed -i 's/product == "HM-CCU2"/product == "HM-dccu2-x86_64"/' $DOCKER_BUILD/www/webui/webui.js
sed -i 's/http:\/\/update.homematic.com\/firmware\/download?cmd=js_check_version&version="+WEBUI_VERSION+"&product=HM-CCU2&serial=" + serial/https:\/\/gitcdn.xyz\/repo\/litti\/dccu2\/master\/release\/latest-release.js?cmd=js_check_version&version="+WEBUI_VERSION+"&product=HM-dccu2-x86_64&serial=" + serial/' $DOCKER_BUILD/www/webui/webui.js

echo "homematic.com.setLatestVersion('$CCU2_VERSION', 'HM-dccu2-x86_64');" > $RDIR/release/latest-release.js

# image specific data
echo "building image specific data"
cp -rl $RDIR/dependencies/occu/firmware $DOCKER_BUILD/firmware/

#copy patched files
echo "copy patched files"
cp -rlf $RDIR/x86_32_debian_all/patches/WebUI/www/config/* $DOCKER_BUILD/www/config/

# other data
echo "building other data"
cp -rlf $RDIR/all/* $DOCKER_BUILD/
cp -rlf $RDIR/x86_32_debian_all/* $DOCKER_BUILD/

docker build -t $DOCKER_ID -t ${DOCKER_ID}:${CCU2_VERSION} $DOCKER_BUILD

echo "#!/bin/sh" >push.sh
echo "docker push $DOCKER_ID" >>push.sh
echo "docker push ${DOCKER_ID}:${CCU2_VERSION}" >>push.sh
