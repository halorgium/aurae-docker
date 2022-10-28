#!/usr/bin/env bash

set -uex -o pipefail

if [ $# -eq 0 ]; then
	CMD=boot-daemon.sh
else
	CMD=$*
fi
docker run -ti --rm --name auraed aurae-runtime $CMD
