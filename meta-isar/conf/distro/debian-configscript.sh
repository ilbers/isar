#!/bin/sh
#
# This software is a part of ISAR.
# Copyright (C) 2015-2017 ilbers GmbH

set -e

readonly MACHINE_SERIAL="$1"
readonly BAUDRATE_TTY="$2"

# Create console device
if [ ! -e /dev/console ]; then
     mknod /dev/console c 5 1
fi

# Enable tty conditionally, systemd does not have the file but its own magic
if [ -f /etc/inittab ]; then
    echo "T0:23:respawn:/sbin/getty -L $MACHINE_SERIAL $BAUDRATE_TTY vt100" \
        >> /etc/inittab
fi
