#!/bin/sh

# Checks system unit until it gets active or retry count reaches the limit

set -e

unit=$1
cnt=$2

ret=1

while [ "$cnt" -gt 0 ]; do
  if systemctl is-active "${unit}"; then
    exit 0
  else
    ret=$?
  fi

  cnt=$((cnt - 1))
  sleep 1
done

exit $ret
