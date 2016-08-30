# Root filesystem for target installation
#
# This software is a part of ISAR.
# Copyright (C) 2015-2016 ilbers GmbH

DESCRIPTION = "Multistrap target filesystem"

LICENSE = "gpl-2.0"
LIC_FILES_CHKSUM = "file://${LAYERDIR_isar}/licenses/COPYING.GPLv2;md5=751419260aa954499f7abaabaa882bbe"

PV = "1.0"

IMAGE_INSTALL ?= ""
DEPENDS += "${IMAGE_INSTALL}"

DEBIAN_DISTRO ?= "wheezy"
DEBIAN_PACKAGES ?= ""

S = "${WORKDIR}/rootfs"

inherit image

do_rootfs() {
    # Copy config file
    install -m 644 ${THISDIR}/files/buildroot.conf ${WORKDIR}

    # Patch the config
    echo "suite=${DEBIAN_DISTRO}" >> ${WORKDIR}/buildroot.conf
    echo "packages=${DEBIAN_PACKAGES}" >> ${WORKDIR}/buildroot.conf

    sudo multistrap -a armhf -d "${S}" -f "${WORKDIR}/buildroot.conf" || true
    sudo install -m 755 /usr/bin/qemu-arm-static ${S}/usr/bin
    sudo install -m 755 ${THISDIR}/files/config.sh ${S}

    sudo chroot ${S} /config.sh
    sudo rm ${S}/config.sh
}
addtask rootfs before do_populate


