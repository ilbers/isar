#
# Copyright (c) Siemens AG, 2023-2024
#
# SPDX-License-Identifier: MIT

require recipes-bsp/trusted-firmware-a/trusted-firmware-a-custom.inc

SRC_URI += "https://git.trustedfirmware.org/TF-A/trusted-firmware-a.git/snapshot/trusted-firmware-a-${PV}.tar.gz"
SRC_URI[sha256sum] = "88215a62291b9ba87da8e50b077741103cdc08fb6c9e1ebd34dfaace746d3201"

S = "${WORKDIR}/trusted-firmware-a-${PV}"

TF_A_PLATFORM = "k3"
TF_A_EXTRA_BUILDARGS = "CFG_ARM64=y TARGET_BOARD=lite SPD=opteed"
TF_A_BINARIES = "lite/release/bl31.bin"
