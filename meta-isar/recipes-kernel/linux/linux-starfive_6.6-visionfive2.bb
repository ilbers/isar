#
# Copyright (c) Siemens AG, 2023-2024
#
# SPDX-License-Identifier: MIT

require recipes-kernel/linux/linux-custom.inc

SRC_URI += " \
    https://github.com/starfive-tech/linux/archive/${SRCREV}.tar.gz;downloadfilename=linux-starfive-${SRCREV}.tar.gz \
    file://0001-riscv-efistub-Ensure-GP-relative-addressing-is-not-u.patch \
    file://starfive2_extra.cfg"
SRCREV = "9fe004eaf1aa5b23bd5d03b4cfe9c3858bd884c4"
SRC_URI[sha256sum] = "9eaf7659aa57e2c5b399b7b33076f1376ec43ef343680e0a57e0a2a9bef6c0ae"

S = "${WORKDIR}/linux-${SRCREV}"

KERNEL_DEFCONFIG = "starfive_visionfive2_defconfig"

LINUX_VERSION_EXTENSION = "-isar"

COMPATIBLE_MACHINE = "starfive-visionfive2"
