#!/usr/bin/env sh
#
# Shell script for helth check based on Docker inspect (via REST API)
#
# Author:       vaclav.sykora@intraworlds.com
# Date:         2017-05-29
# Licence:      Copyright 2016 IntraWorlds s.r.o. (MIT LICENCE)
# Dependencies: curl,mktemp,grep,awk,sed,tr,echo
# Example:
#   $ ./docker-health-check.sh container_id

# exit the script when a command fails
set -o errexit

if [ $# -eq 0 ]; then
    echo 'No Docker ID supplied'
    exit 1
fi

inspect=$(curl --fail --silent --unix-socket /var/run/docker.sock http://localhost:5555/containers/$1/json)
if [ -z "$inspect" ]; then
    echo "blank 'inspect' value"
    exit 2
fi

status=$(echo $inspect | grep -o '"Health":{[^}]*"Status":"[a-zA-Z]*"' | awk -F ":" '{ print $NF }' | tr -d '"')
if [ -z "$status" ]; then
    echo "failed to identify healthy status"
    exit 3
fi
if [ "$status" != "healthy" ]; then
    echo "not healthy, status=$status"
    exit 10
fi

echo $status
