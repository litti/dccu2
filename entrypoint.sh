#!/bin/sh

echo "Now starting CCU2 from docker :-)"

/bin/run-parts -a start /etc/rc3.d

echo
echo "Register trap for TERM"
finish () {
	echo "Stopping CCU2 from docker :-("
	/bin/run-parts -a stop /etc/rc3.d
  exit 0
}

echo "Now running CCU2 from docker :-)"
ip addr show|grep inet|grep global|awk '{print "Meine IP-Adresse ist: " $2}'

trap finish TERM

while true; do
  #send local time to rf lan gateways because they have no rtc and we want the right time on the displays :-)
  /bin/SetInterfaceClock 127.0.0.1:2001
  sleep 30m
done
