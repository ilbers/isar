#!/bin/sh

# Checks global status of all services

set -e

cnt=$1

ret=1

while [ 0${cnt} -gt 0 ]; do
  if systemctl is-system-running; then
    exit 0
  else
    ret=$?
  fi

  cnt=$((cnt - 1))
  sleep 1
done

exit $ret
