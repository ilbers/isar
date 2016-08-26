# Sample application
#
# Copyright (C) 2015-2016 ilbers GmbH

DESCRIPTION = "Sample application for ISAR"

LICENSE = "gpl-2.0"
LIC_FILES_CHKSUM = "file://${LAYERDIR_isar}/licenses/COPYING.GPLv2;md5=751419260aa954499f7abaabaa882bbe"

PV = "1.0"

SRC_URI = "\
    file://hello.c  \
    file://Makefile \
"

inherit dpkg

S = "${WORKDIR}"

DEPLOYDIR = "${WORKDIR}/../devroot/deploy"

do_build() {
    sudo install -m 644 ${THISDIR}/hello/hello.c ${BUILDROOT}
    sudo install -m 644  ${THISDIR}/hello/Makefile ${BUILDROOT}

    sudo chroot ${BUILDROOTDIR} /usr/bin/make -C /home/builder/${PN}
}

addtask do_install after do_build

do_install() {
    install -d ${DEPLOYDIR}
    install -m 755 ${BUILDROOT}/hello ${DEPLOYDIR}
}
