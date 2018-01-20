#!/bin/sh

echo "starting ssh"
/etc/init.d/ssh start

echo "Running CCU2 from docker :-)"
for f in /etc/init.d/ccu2-*
do
  echo "Processing startup script $f"
  "$f" start
done

echo
echo "Register trap for TERM"
finish () {
	echo "Stopping CCU2 from docker :-)"
	for f in /etc/init.d/ccu2-*
	do
	  echo "Processing startup script $f"
	  "$f" stop
	done
  exit 0
}
trap finish TERM

while true; do
  #send local time to rf lan gateways because they have no rtc and we want the tight time on the displays :-)
  /bin/SetInterfaceClock 127.0.0.1:2001
  sleep 30m
done
