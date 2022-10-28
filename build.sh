#!/usr/bin/env bash

set -uex -o pipefail

docker build -f Dockerfile --tag aurae-runtime .
