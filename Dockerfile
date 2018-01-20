FROM debian:jessie

ARG DEBIAN_FRONTEND=noninteractive

ADD bin /bin
ADD etc /etc
ADD firmware /firmware
ADD lib /lib
ADD opt /opt
ADD usr /usr
ADD www /www

RUN rm -rf /usr/local/*
RUN mkdir -p /usr/local/etc/config
RUN mkdir -p /usr/local/etc/config/rc.d
RUN mkdir -p /usr/local/etc/config/addons/www
RUN mkdir -p /var/status
RUN ln -s ../usr/local/etc/config /etc/config
RUN dpkg --add-architecture i386
RUN apt-get update
RUN apt-get install -y --no-install-recommends apt-utils
RUN apt-get install -y bootlogd busybox-syslogd curl file kmod net-tools openssh-server openssl patch psmisc rsync software-properties-common usbutils vim wget
RUN apt-get install -y libc6:i386 libncurses5:i386 libssl-dev:i386 libstdc++6:i386 libusb-1.0:i386
RUN apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv-keys 0x219BD9C9
RUN apt-add-repository 'deb http://repos.azulsystems.com/debian stable main'
RUN apt-get update
RUN apt-get install -y zulu-8
RUN mkdir /opt/hm
RUN touch /var/rf_address
RUN ln -s /www /opt/hm/www
RUN ln -s /bin /opt/hm/bin
RUN update-usbids
RUN echo "root:MuZhlo9n%8!G"|chpasswd
RUN sed -i -e 's/^PermitRootLogin without-password/PermitRootLogin yes/g' /etc/ssh/sshd_config

ADD entrypoint.sh /

CMD ["/entrypoint.sh"]

#ssh
EXPOSE 22
#webui
EXPOSE 80
#minissdpd
EXPOSE 1900
EXPOSE 1999
#rfd
EXPOSE 2001
#hs485d
EXPOSE 2002
#hmiprf 
EXPOSE 2010
#rega
EXPOSE 8181
#virtualdevices
EXPOSE 9292