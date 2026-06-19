#!/bin/sh
# This software is a part of Isar.
# Copyright (C) Siemens AG, 2026
#
# SPDX-License-Identifier: MIT

set -e

OVERRIDE_DIR="/usr/lib/systemd/system"
DROP_IN_SUFFIX="d/10-target-bootstrapper.override.conf"

# Check if override template exists
if [ ! -f "/usr/lib/target-bootstrapper.override.conf" ]; then
    exit 0
fi

# Detect first available serial device (ttyACM*, ttyUSB*, ttyAMA*, etc.)
detect_first_serial_device() {
    for pattern in ttyACM ttyUSB ttyAMA ttyGS; do
        for dev in /dev/${pattern}*; do
            if [ -c "$dev" ]; then
                basename "$dev"
                return 0
            fi
        done
    done
}

DETECTED_TTY=$(detect_first_serial_device 2>/dev/null)

if [ -z "$DETECTED_TTY" ]; then
    exit 0
fi

# Map device name to getty service instance
# e.g. ttyACM0 -> serial-getty@ttyACM0.service
TTY_SERVICE="serial-getty@${DETECTED_TTY}.service"
DROP_IN_DIR="${OVERRIDE_DIR}/${TTY_SERVICE}.d"

# Create drop-in directory and install override
mkdir -p "$DROP_IN_DIR"
cp "/usr/lib/target-bootstrapper.override.conf" "$DROP_IN_DIR/${DROP_IN_SUFFIX##*/}"

# Reload systemd to pick up new drop-ins
systemctl daemon-reload || true

exit 0
