# This software is a part of ISAR.
# Copyright (C) 2025 Siemens

inherit dpkg

DESCRIPTION = "Raspberry Pi firmware blobs"
MAINTAINER = "isar-users <isar-users@googlegroups.com>"

SRC_URI = " \
    https://github.com/raspberrypi/firmware/archive/${PV}.tar.gz;downloadfilename=${PN}-${PV}.tar.gz \
    file://debian/install \
    file://debian/rules \
"
SRC_URI[sha256sum] = "4981021b82f600f450d64d9b82034dc603bf5429889a3947b2863e01992a343c"

S = "${WORKDIR}/firmware-${PV}"

do_prepare_build[cleandirs] += "${S}/debian"
do_prepare_build() {
    deb_debianize
    cp -r ${WORKDIR}/debian ${S}
}
