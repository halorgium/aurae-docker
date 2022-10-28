#!/usr/bin/env bash

set -uex -o pipefail

/etc/init.d/busybox-syslogd start
gosu aurae auraed
