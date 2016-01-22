#!/bin/bash

for host in $(cat gluster_hosts); do
	echo "Stopping ${host}..."
	ssh ${host} "killall find_all_files.sh; killall find_files.pl"
	echo
done
