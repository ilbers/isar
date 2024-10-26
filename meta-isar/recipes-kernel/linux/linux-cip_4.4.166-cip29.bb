# Example recipe for building the CIP 4.4 kernel
#
# This software is a part of ISAR.
# Copyright (c) Siemens AG, 2024
#
# SPDX-License-Identifier: MIT

require recipes-kernel/linux/linux-custom.inc

SRC_URI += " \
    git://git.kernel.org/pub/scm/linux/kernel/git/cip/linux-cip.git;branch=linux-4.4.y-cip;destsuffix=${P} \
    file://x86_64_defconfig"

SRCREV = "af3adf9f9c633ac0e1d68487d7fad22285dda8a3"

KERNEL_DEFCONFIG:qemuamd64-cip = "x86_64_defconfig"
