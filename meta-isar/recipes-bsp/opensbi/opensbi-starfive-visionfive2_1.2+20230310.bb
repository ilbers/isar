#
# Copyright (c) Siemens AG, 2023
#
# SPDX-License-Identifier: MIT

inherit dpkg

DESCRIPTION = "OpenSBI firmware for StarFive VisionFive 2"

SRC_URI = " \
    git://github.com/riscv-software-src/opensbi.git;destsuffix=opensbi-${PV};protocol=https;branch=master \
    file://starfive-visionfive2-rules"
# required patches are not yet part of a release, but will be in 1.3
SRCREV = "2868f26131308ff345382084681ea89c5b0159f1"

S = "${WORKDIR}/opensbi-${PV}"

do_prepare_build[cleandirs] += "${S}/debian"
do_prepare_build() {
    cp ${WORKDIR}/starfive-visionfive2-rules ${WORKDIR}/rules
    deb_debianize

    echo "build/platform/generic/firmware/fw_dynamic.bin /usr/lib/opensbi/starfive-visionfive2/" > ${S}/debian/install
}

COMPATIBLE_MACHINE = "starfive-visionfive2"
