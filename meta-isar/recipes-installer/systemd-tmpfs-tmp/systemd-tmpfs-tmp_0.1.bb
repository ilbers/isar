# This software is a part of ISAR.
# Copyright (C) Siemens AG, 2025
#
# SPDX-License-Identifier: MIT

inherit dpkg-raw

DESCRIPTION = "Configures /tmp as systemd-managed temporary filesystem (tmpfs), ensuring read-write access even if rootfs is read-only"
MAINTAINER = "isar-users <isar-users@googlegroups.com>"

SRC_URI = "file://postinst"

DEBIAN_DEPENDS = "systemd"
