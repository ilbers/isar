# SDK Root filesystem
#
# This software is a part of ISAR.
# Copyright (C) 2015-2018 ilbers GmbH

DESCRIPTION = "Isar SDK Root filesystem"

LICENSE = "gpl-2.0"
LIC_FILES_CHKSUM = "file://${LAYERDIR_core}/licenses/COPYING.GPLv2;md5=751419260aa954499f7abaabaa882bbe"

inherit dpkg-raw

SRC_URI = " \
    file://configscript.sh \
    file://relocate-sdk.sh \
    file://gcc-sysroot-wrapper.sh \
    file://README.sdk"
PV = "0.1"

do_install() {
    install -m 644 ${WORKDIR}/README.sdk ${D}
    install -m 755 ${WORKDIR}/relocate-sdk.sh ${D}
    install -m 755 -d ${D}/usr/bin
    install -m 755 ${WORKDIR}/gcc-sysroot-wrapper.sh ${D}/usr/bin
    install -m 755 ${WORKDIR}/configscript.sh ${D}
}
