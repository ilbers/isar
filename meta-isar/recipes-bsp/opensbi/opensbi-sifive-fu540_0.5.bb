#
# Copyright (c) Siemens AG, 2020
#
# SPDX-License-Identifier: MIT

inherit dpkg

SRC_URI = " \
    https://github.com/riscv/opensbi/archive/v${PV}.tar.gz;downloadfilename=opensbi-${PV}.tar.gz \
    file://sifive-fu540-rules"
SRC_URI[sha256sum] = "bc82f1e63663cafb7976b324d8a01263510cfd816063dc89e0ccffb9763fb1dd"

S = "${WORKDIR}/opensbi-${PV}"

do_prepare_build[cleandirs] += "${S}/debian"
do_prepare_build() {
    cp ${WORKDIR}/sifive-fu540-rules ${WORKDIR}/rules
    deb_debianize

    sed -i 's/\(Build-Depends:.*\)/\1, u-boot-sifive/' ${S}/debian/control

    echo "build/platform/sifive/fu540/firmware/fw_payload.bin /usr/lib/opensbi/sifive-fu540/" > ${S}/debian/install
}
