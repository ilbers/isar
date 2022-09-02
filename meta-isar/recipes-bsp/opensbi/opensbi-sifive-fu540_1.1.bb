#
# Copyright (c) Siemens AG, 2020
#
# SPDX-License-Identifier: MIT

inherit dpkg

SRC_URI = " \
    https://github.com/riscv/opensbi/archive/v${PV}.tar.gz;downloadfilename=opensbi-${PV}.tar.gz \
    file://sifive-fu540-rules"
SRC_URI[sha256sum] = "d183cb890130983a4f01e75fc03ee4f7ea0e16a7923b8af9c6dff7deb2fedaec"

S = "${WORKDIR}/opensbi-${PV}"

DEBIAN_BUILD_DEPENDS = "u-boot-sifive"

do_prepare_build[cleandirs] += "${S}/debian"
do_prepare_build() {
    cp ${WORKDIR}/sifive-fu540-rules ${WORKDIR}/rules
    deb_debianize

    echo "build/platform/generic/firmware/fw_payload.bin /usr/lib/opensbi/sifive-fu540/" > ${S}/debian/install
}
