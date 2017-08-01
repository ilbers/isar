# Root filesystem for target installation
#
# This software is a part of ISAR.
# Copyright (C) 2015-2017 ilbers GmbH

DESCRIPTION = "Multistrap target filesystem"

LICENSE = "gpl-2.0"
LIC_FILES_CHKSUM = "file://${LAYERDIR_isar}/licenses/COPYING.GPLv2;md5=751419260aa954499f7abaabaa882bbe"

PV = "1.0"

inherit image

DEPENDS += "${IMAGE_INSTALL}"

IMAGE_PREINSTALL += "apt \
                     dbus"

WORKDIR = "${TMPDIR}/work/${PN}/${MACHINE}"
S = "${WORKDIR}/rootfs"
IMAGE_ROOTFS = "${S}"

do_rootfs[stamp-extra-info] = "${MACHINE}"

do_rootfs() {
    install -d -m 755 ${WORKDIR}/hooks_multistrap

    # Copy config file
    install -m 644 ${FILESDIR}/multistrap.conf.in ${WORKDIR}/multistrap.conf
    install -m 755 ${FILESDIR}/${DISTRO_CONFIG_SCRIPT} ${WORKDIR}/configscript.sh
    install -m 755 ${FILESDIR}/setup.sh ${WORKDIR}
    install -m 755 ${FILESDIR}/download_dev-random ${WORKDIR}/hooks_multistrap/

    # Adjust multistrap config
    sed -i 's|##IMAGE_PREINSTALL##|${IMAGE_PREINSTALL}|' ${WORKDIR}/multistrap.conf
    sed -i 's|##DISTRO##|${DISTRO}|' ${WORKDIR}/multistrap.conf
    sed -i 's|##DISTRO_APT_SOURCE##|${DISTRO_APT_SOURCE}|' ${WORKDIR}/multistrap.conf
    sed -i 's|##DISTRO_SUITE##|${DISTRO_SUITE}|' ${WORKDIR}/multistrap.conf
    sed -i 's|##DISTRO_COMPONENTS##|${DISTRO_COMPONENTS}|' ${WORKDIR}/multistrap.conf
    sed -i 's|##CONFIG_SCRIPT##|./tmp/work/${PN}/${MACHINE}/configscript.sh|' ${WORKDIR}/multistrap.conf
    sed -i 's|##SETUP_SCRIPT##|./tmp/work/${PN}/${MACHINE}/setup.sh|' ${WORKDIR}/multistrap.conf
    sed -i 's|##DIR_HOOKS##|./tmp/work/${PN}/${MACHINE}/hooks_multistrap|' ${WORKDIR}/multistrap.conf

    # Multistrap config use relative paths, so ensure that we are in the right folder
    cd ${TOPDIR}

    # Create root filesystem
    sudo multistrap -a ${DISTRO_ARCH} -d "${S}" -f "${WORKDIR}/multistrap.conf" || true

    # Configure root filesystem
    sudo chroot ${S} /configscript.sh ${MACHINE_SERIAL} ${BAUDRATE_TTY} \
        ${ROOTFS_DEV}
    sudo rm ${S}/configscript.sh
}

addtask rootfs before do_populate
