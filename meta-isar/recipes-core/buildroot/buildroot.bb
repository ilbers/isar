# Root filesystem for packages building
#
# Copyright (C) 2015-2016 ilbers GmbH

DESCRIPTION = "Multistrap development filesystem"

LICENSE = "gpl-2.0"
LIC_FILES_CHKSUM = "file://${LAYERDIR_isar}/licenses/COPYING.GPLv2;md5=751419260aa954499f7abaabaa882bbe"

PV = "1.0"

DEBIAN_DISTRO ?= "wheezy"
DEBIAN_TOOLS ?= "gcc make build-essential"

SCR_URI = "\
    file://buildroot.conf \
    file://LICENSE        \
"

do_build() {
    # Copy config file
    install -m 644 ${THISDIR}/files/buildroot.conf ${WORKDIR}

    # Patch the config
    echo "suite=${DEBIAN_DISTRO}" >> ${WORKDIR}/buildroot.conf
    echo "packages=${DEBIAN_TOOLS}" >> ${WORKDIR}/buildroot.conf

    sudo multistrap -a armhf -d "${BUILDROOTDIR}" -f "${WORKDIR}/buildroot.conf" || true
    sudo install -m 755 /usr/bin/qemu-arm-static ${BUILDROOTDIR}/usr/bin
}
