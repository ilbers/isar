#
# Copyright (c) Siemens AG, 2023
#
# SPDX-License-Identifier: MIT

require recipes-kernel/linux/linux-custom.inc

SRC_URI += " \
    git://github.com/starfive-tech/linux.git;protocol=https;branch=JH7110_VisionFive2_devel;destsuffix=linux-visionfive-${PV} \
    file://starfive2_extra.cfg"
SRCREV = "a87c6861c6d96621026ee53b94f081a1a00a4cc7"

S = "${WORKDIR}/linux-visionfive-${PV}"

KERNEL_DEFCONFIG = "starfive_visionfive2_defconfig"

LINUX_VERSION_EXTENSION = "-isar"
