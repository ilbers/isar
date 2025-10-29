#
# Copyright (c) Siemens AG, 2020
#
# SPDX-License-Identifier: MIT

inherit opensbi

SRC_URI += "https://github.com/riscv/opensbi/archive/v${PV}.tar.gz;downloadfilename=opensbi-${PV}.tar.gz"
SRC_URI[sha256sum] = "d183cb890130983a4f01e75fc03ee4f7ea0e16a7923b8af9c6dff7deb2fedaec"

S = "${WORKDIR}/opensbi-${PV}"

DEBIAN_BUILD_DEPENDS = "u-boot-sifive"

OPENSBI_EXTRA_BUILDARGS = "FW_PAYLOAD_PATH=/usr/lib/u-boot/sifive_unleashed/u-boot.bin"
OPENSBI_BIN = "fw_payload.bin"

COMPATIBLE_MACHINE = "sifive-fu540"
