#!/bin/sh

echo "Configuring the packages with chroot"

TARGET=$1

sudo chroot ${TARGET} /configscript.sh
