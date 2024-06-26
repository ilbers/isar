#
# Copyright (c) Siemens AG, 2023-2024
#
# SPDX-License-Identifier: MIT

require recipes-bsp/trusted-firmware-a/trusted-firmware-a-custom.inc

SRC_URI += "https://github.com/ARM-software/arm-trusted-firmware/archive/v${PV}.tar.gz;downloadfilename=arm-trusted-firmware-${PV}.tar.gz"

S = "${WORKDIR}/arm-trusted-firmware-${PV}"

TF_A_PLATFORM = "k3"
TF_A_EXTRA_BUILDARGS = "CFG_ARM64=y TARGET_BOARD=lite SPD=opteed"
TF_A_BINARIES = "lite/release/bl31.bin"

COMPATIBLE_MACHINE = "beagleplay"
