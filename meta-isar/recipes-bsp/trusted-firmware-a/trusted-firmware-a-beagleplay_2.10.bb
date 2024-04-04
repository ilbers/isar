#
# Copyright (c) Siemens AG, 2023-2024
#
# SPDX-License-Identifier: MIT

require recipes-bsp/trusted-firmware-a/trusted-firmware-a-custom.inc

SRC_URI += "git://git.trustedfirmware.org/TF-A/trusted-firmware-a.git;protocol=https;branch=master"
SRCREV = "b6c0948400594e3cc4dbb5a4ef04b815d2675808"

S = "${WORKDIR}/git"

TF_A_PLATFORM = "k3"
TF_A_EXTRA_BUILDARGS = "CFG_ARM64=y TARGET_BOARD=lite SPD=opteed"
TF_A_BINARIES = "lite/release/bl31.bin"
