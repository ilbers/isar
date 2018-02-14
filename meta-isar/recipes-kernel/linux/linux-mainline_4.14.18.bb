# Example recipe for building the mainline kernel
#
# This software is a part of ISAR.
# Copyright (c) Siemens AG, 2018
#
# SPDX-License-Identifier: MIT

require recipes-kernel/linux/linux-custom.inc

SRC_URI += " \
    https://cdn.kernel.org/pub/linux/kernel/v4.x/linux-${PV}.tar.xz \
    file://x86_64_defconfig"
SRC_URI[sha256sum] = "866a94c1c38d923ae18e74b683d7a8a79b674ebdfe7f40f1a3be9a27d39fe354"

S = "linux-${PV}"

KERNEL_DEFCONFIG_qemuamd64 = "x86_64_defconfig"
