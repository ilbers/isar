#!/bin/sh
#
# Update rootfs device in fstab, enable checks for all regular filesystems
#
# This software is a part of ISAR.
# Copyright (c) Siemens AG, 2018
#
# SPDX-License-Identifier: MIT

set -e

ROOT_DEV="$(/bin/findmnt -n -o SOURCE /)"
sed -i -e 's|^/dev/root\([ 	]\+.*[ 	]\+\)0[ 	]\+0|'"$ROOT_DEV"'\10	1|' \
       -e 's|^\(/dev/.*[ 	]\+\)0[ 	]\+0|\10	2|' /etc/fstab
