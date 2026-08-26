# Example recipe for building the CIP 4.4 kernel
#
# This software is a part of Isar.
# Copyright (c) Siemens AG, 2024
#
# SPDX-License-Identifier: MIT

inherit linux-kernel

SRC_URI += " \
    git://git.kernel.org/pub/scm/linux/kernel/git/cip/linux-cip.git;protocol=https;branch=linux-4.4.y-cip;destsuffix=${P} \
"

SRCREV = "af3adf9f9c633ac0e1d68487d7fad22285dda8a3"

SRC_URI:append:amd64 = " file://${KERNEL_DEFCONFIG}"
KERNEL_DEFCONFIG:amd64 = "x86_64_defconfig"
