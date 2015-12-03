# Sample application
#
# Copyright (C) 2015-2016 ilbers GmbH

inherit zynq-image

DESCRIPTION = "Multistrap Root Filesystem"

LICENSE = "gpl-2.0"
LIC_FILES_CHKSUM = "file://LICENSE;md5=b234ee4d69f5fce4486a80fdaf4a4263"

PV = "1.0"

DEPENDS += "multi-devroot"

SRC_URI = "\
    file://hello.c \
    file://LICENSE        \
    file://Makefile       \
"

S = "${WORKDIR}"

DEVROOT = "${WORKDIR}/../devroot/rootfs"
BUILDROOT = "${DEVROOT}/home/builder/${PN}"
DEPLOYDIR = "${WORKDIR}/../devroot/deploy"

do_build() {
    # TODO: Integrate Debian package building
    mkdir -p ${PKG_DIR}

    sudo install -d ${BUILDROOT}
    sudo install -m 644 ${THISDIR}/hello/hello.c ${BUILDROOT}
    sudo install -m 644  ${THISDIR}/hello/Makefile ${BUILDROOT}

    sudo chroot ${DEVROOT} /usr/bin/make -C /home/builder/${PN}
}

addtask do_install after do_build

do_install() {
    install -d ${DEPLOYDIR}
    install -m 755 ${BUILDROOT}/hello ${DEPLOYDIR}
}

do_build[deptask] = "do_build"
