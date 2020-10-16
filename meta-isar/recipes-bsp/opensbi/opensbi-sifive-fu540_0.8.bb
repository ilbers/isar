#
# Copyright (c) Siemens AG, 2020
#
# SPDX-License-Identifier: MIT

inherit dpkg

SRC_URI = " \
    https://github.com/riscv/opensbi/archive/v${PV}.tar.gz;downloadfilename=opensbi-${PV}.tar.gz \
    file://sifive-fu540-rules"
SRC_URI[sha256sum] = "17e048ac765e92e15f7436b604452614cf88dc2bcbbaab18cdc024f3fdd4c575"

S = "${WORKDIR}/opensbi-${PV}"

DEBIAN_BUILD_DEPENDS = "u-boot-sifive"

do_prepare_build[cleandirs] += "${S}/debian"
do_prepare_build() {
    cp ${WORKDIR}/sifive-fu540-rules ${WORKDIR}/rules
    deb_debianize

    echo "build/platform/sifive/fu540/firmware/fw_payload.bin /usr/lib/opensbi/sifive-fu540/" > ${S}/debian/install
}
