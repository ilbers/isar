# Kselftest package
#
# This software is a part of ISAR.
# Copyright (c) Mentor Graphics, a Siemens business, 2020
# Copyright (c) Siemens, 2025
#
# SPDX-License-Identifier: MIT

inherit linux-kselftest

SRC_URI += "https://cdn.kernel.org/pub/linux/kernel/v6.x/linux-${PV}.tar.xz"
SRC_URI[sha256sum] = "a1d2cd7327f10eec022615c1bb12c06439bd110d2020164be97f698f43ca58be"
