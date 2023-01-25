# This software is a part of ISAR.
#
# Copyright (c) Siemens AG, 2020
#
# SPDX-License-Identifier: MIT

inherit dpkg-raw

DPKG_ARCH = "all"
# build this package using the host toolchain
# to break cyclic dependency in the cross chroot
PACKAGE_ARCH = "${HOST_ARCH}"

DEBIAN_DEPENDS = " \
    gcc-riscv64-linux-gnu, \
    g++-riscv64-linux-gnu, \
    dpkg-cross"
