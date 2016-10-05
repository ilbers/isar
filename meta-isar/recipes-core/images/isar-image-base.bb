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
    install -m 644 ${THISDIR}/files/multistrap.conf.in ${WORKDIR}/multistrap.conf
    install -m 755 ${THISDIR}/files/configscript.sh ${WORKDIR}
    install -m 755 ${THISDIR}/files/setup.sh ${WORKDIR}

    # Adjust multistrap config
    echo "suite=${DEBIAN_DISTRO}" >> ${WORKDIR}/multistrap.conf
    echo "packages=${DEBIAN_PACKAGES}" >> ${WORKDIR}/multistrap.conf
    sed -i '/^configscript=/ s#$#../configscript.sh#' ${WORKDIR}/multistrap.conf
    sed -i '/^setupscript=/ s#$#../setup.sh#' ${WORKDIR}/multistrap.conf

    # Create root filesystem
    sudo multistrap -a armhf -d "${S}" -f "${WORKDIR}/multistrap.conf" || true

    # Configure root filesystem
    sudo chroot ${S} /configscript.sh
    sudo rm ${S}/configscript.sh
}

addtask rootfs before do_populate
