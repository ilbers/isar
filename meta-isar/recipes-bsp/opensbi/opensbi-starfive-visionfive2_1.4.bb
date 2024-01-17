#
# Copyright (c) Siemens AG, 2023
#
# SPDX-License-Identifier: MIT

inherit dpkg

DESCRIPTION = "OpenSBI firmware for StarFive VisionFive 2"

SRC_URI = " \
    https://github.com/riscv-software-src/opensbi/archive/refs/tags/v${PV}.tar.gz;downloadfilename=opensbi-${PV}.tar.gz \
    file://starfive-visionfive2-rules"
SRC_URI[sha256sum] = "319b62a4186fbce9b81a0c5f0ec9f003a10c808397a72138bc9745d9b87b1eb1"

S = "${WORKDIR}/opensbi-${PV}"

do_prepare_build[cleandirs] += "${S}/debian"
do_prepare_build() {
    cp ${WORKDIR}/starfive-visionfive2-rules ${WORKDIR}/rules
    deb_debianize

    echo "build/platform/generic/firmware/fw_dynamic.bin /usr/lib/opensbi/starfive-visionfive2/" > ${S}/debian/install
}

COMPATIBLE_MACHINE = "starfive-visionfive2"
