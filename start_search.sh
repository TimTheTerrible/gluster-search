#!/bin/bash

for host in $(cat gluster_hosts); do
	echo "Starting ${host}..."
	ssh -f ${host} "./find_all_files.sh"
done
