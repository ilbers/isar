# Kselftest package
#
# This software is a part of Isar.
# Copyright (c) Mentor Graphics, a Siemens business, 2020
# Copyright (c) Siemens, 2025
#
# SPDX-License-Identifier: MIT

inherit linux-kselftest

MAINTAINER = "isar-users <isar-users@googlegroups.com>"

SRC_URI += "https://cdn.kernel.org/pub/linux/kernel/v6.x/linux-${PV}.tar.xz"
SRC_URI[sha256sum] = "e35ac999f40a6874493d8d60f33f1150d7a89ae5841c428da82257fbcd070aed"
