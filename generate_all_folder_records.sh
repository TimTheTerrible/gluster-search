#!/bin/bash

echo $1
if [ "x$1" == "xdebug" ]; then
	ARGS="--debug=all --test --limit"
else
	ARGS="--debug=error,warn,info --no-test --no-limit"
fi

GLUSTER_HOSTS=$(cat gluster_hosts)
BRICKS="brick00 brick01 brick02"

for HOST in ${GLUSTER_HOSTS}; do
	echo "Generate folder records for ${HOST}..."
	for BRICK in ${BRICKS}; do
		echo "  Populate records for brick ${BRICK}..."
		./populate_folder_records.pl --host=${HOST} --brick=${BRICK} ${ARGS};
	done
done
