# This software is a part of ISAR.
#
# Copyright (c) Siemens AG, 2020
#
# SPDX-License-Identifier: MIT

inherit dpkg-raw

DPKG_ARCH = "all"

ISAR_CROSS_BUILD = "0"

DEBIAN_DEPENDS = " \
    gcc-riscv64-linux-gnu, \
    g++-riscv64-linux-gnu, \
    dpkg-cross"
