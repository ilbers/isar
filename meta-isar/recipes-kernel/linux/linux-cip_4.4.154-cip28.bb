# Example recipe for building the CIP 4.4 kernel
#
# This software is a part of ISAR.
# Copyright (c) Siemens AG, 2018
#
# SPDX-License-Identifier: MIT

require recipes-kernel/linux/linux-custom.inc

SRC_URI += " \
    git://git.kernel.org/pub/scm/linux/kernel/git/bwh/linux-cip.git;branch=linux-4.4.y-cip;destsuffix=${P} \
    file://x86_64_defconfig"

SRCREV = "5dcb70a7e56e2c00e1c8ca593c61e378cef22f51"

KERNEL_DEFCONFIG_qemuamd64 = "x86_64_defconfig"
