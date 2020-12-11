#!/bin/bash

restart_lte() {
	mbim-network --profile=/config/user-data/mbim-network.conf /dev/cdc-wdm0 stop
	mbim-network --profile=/config/user-data/mbim-network.conf /dev/cdc-wdm0 start

	/config/scripts/mbim-set-ip /dev/cdc-wdm0 wwan0
}

is_failed() {
	if [[ -f /var/run/load-balance/wlb.out ]] ; then
		output=$(cat /var/run/load-balance/wlb.out | grep -A 1 wwan0)
	fi

	if [[ $output = "*failed*" ]] ; then
		echo 1
	else
		echo 0
	fi
}

if { set -C; 2>/dev/null >/tmp/restart-wwan.lock; }; then
	trap "rm -f /tmp/restart-wwan.lock" EXIT
else
	echo "Lock file exists, exiting..."
	exit
fi

failed=1
timer=10

while [[ $failed -eq 1 ]] ; do
	restart_lte

	sleep $timer

	failed=$(is_failed)

	if [[ $timer -lt 60 ]] ; then
		((timer+=5))
	fi
done
