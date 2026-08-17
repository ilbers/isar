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
SRC_URI[sha256sum] = "f143aaade8877ba5616e788b4482576db28481bcf557ef537f4fcc3938fc3176"
