# Example recipe for building the CIP 4.4 kernel
#
# This software is a part of ISAR.
# Copyright (c) Siemens AG, 2018
#
# SPDX-License-Identifier: MIT

require recipes-kernel/linux/linux-custom.inc

SRC_URI += " \
    git://git.kernel.org/pub/scm/linux/kernel/git/bwh/linux-cip.git;branch=linux-4.4.y-cip \
    file://x86_64_defconfig"

SRCREV = "4e52cc5f668c4666e31a8485725b5f4e897b3baf"
PV = "4.4.112-cip18"

S = "git"

KERNEL_DEFCONFIG_qemuamd64 = "x86_64_defconfig"
