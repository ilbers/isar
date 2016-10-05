# Root filesystem for packages building
#
# This software is a part of ISAR.
# Copyright (C) 2015-2016 ilbers GmbH

DESCRIPTION = "Multistrap development filesystem"

LICENSE = "gpl-2.0"
LIC_FILES_CHKSUM = "file://${LAYERDIR_isar}/licenses/COPYING.GPLv2;md5=751419260aa954499f7abaabaa882bbe"

PV = "1.0"

DEBIAN_DISTRO ?= "wheezy"
DEBIAN_TOOLS ?= "\
                 gcc make build-essential debhelper autotools-dev dpkg locales docbook-to-man apt \
                "

do_build() {
    # Copy config files
    install -m 644 ${THISDIR}/files/multistrap.conf.in ${WORKDIR}/multistrap.conf
    install -m 755 ${THISDIR}/files/configscript.sh ${WORKDIR}
    install -m 755 ${THISDIR}/files/setup.sh ${WORKDIR}

    # Adjust multistrap config
    echo "suite=${DEBIAN_DISTRO}" >> ${WORKDIR}/multistrap.conf
    echo "packages=${DEBIAN_TOOLS}" >> ${WORKDIR}/multistrap.conf
    sed -i '/^configscript=/ s#$#./tmp/work/${PF}/configscript.sh#' ${WORKDIR}/multistrap.conf
    sed -i '/^setupscript=/ s#$#./tmp/work/${PF}/setup.sh#' ${WORKDIR}/multistrap.conf

    # Create root filesystem
    sudo multistrap -a armhf -d "${BUILDROOTDIR}" -f "${WORKDIR}/multistrap.conf" || true

    # Install package builder script
    sudo install -m 755 ${THISDIR}/files/build.sh ${BUILDROOTDIR}

    # Configure root filesystem
    sudo chroot ${BUILDROOTDIR} /configscript.sh
}
