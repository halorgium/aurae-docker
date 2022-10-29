#!/usr/bin/env bash

set -uex -o pipefail

if [ $# -eq 0 ]; then
	CMD="gosu aurae /bin/bash"
else
	CMD=$*
fi
docker exec -ti auraed $CMD
