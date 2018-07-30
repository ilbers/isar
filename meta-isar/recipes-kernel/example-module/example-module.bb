# Example recipe for building a custom module
#
# This software is a part of ISAR.
# Copyright (c) Siemens AG, 2018
#
# SPDX-License-Identifier: MIT

include recipes-kernel/linux-module/module.inc

SRC_URI += "file://src"

S = "${WORKDIR}/src"

AUTOLOAD = "1"

# Cross-compilation is not supported for the default Debian kernels.
# For example, package with kernel headers for ARM:
#   linux-headers-armmp
# has hard dependencies from linux-compiler-gcc-4.8-arm, what
# conflicts with the host binaries.
ISAR_CROSS_COMPILE = "0"
