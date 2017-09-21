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

WORKDIR = "${TMPDIR}/work/${DISTRO}-${DISTRO_ARCH}/${PN}"

do_rootfs[stamp-extra-info] = "${MACHINE}-${DISTRO}"
do_rootfs[dirs] = "${WORKDIR}/hooks_multistrap"

do_rootfs() {
    # Copy config file
    install -m 644 ${THISDIR}/files/multistrap.conf.in ${WORKDIR}/multistrap.conf
    install -m 755 ${THISDIR}/files/${DISTRO_CONFIG_SCRIPT} ${WORKDIR}/configscript.sh
    install -m 755 ${THISDIR}/files/setup.sh ${WORKDIR}
    install -m 755 ${THISDIR}/files/download_dev-random ${WORKDIR}/hooks_multistrap/

    # Multistrap accepts only relative path in configuration files, so get it:
    cd ${TOPDIR}
    WORKDIR_REL=${@ os.path.relpath(d.getVar("WORKDIR", True))}

    # Adjust multistrap config
    sed -i -e 's|##IMAGE_PREINSTALL##|${IMAGE_PREINSTALL}|g' \
           -e 's|##DISTRO##|${DISTRO}|g' \
           -e 's|##DISTRO_APT_SOURCE##|${DISTRO_APT_SOURCE}|g' \
           -e 's|##DISTRO_SUITE##|${DISTRO_SUITE}|g' \
           -e 's|##DISTRO_COMPONENTS##|${DISTRO_COMPONENTS}|g' \
           -e 's|##CONFIG_SCRIPT##|./'"$WORKDIR_REL"'/configscript.sh|g' \
           -e 's|##SETUP_SCRIPT##|./'"$WORKDIR_REL"'/setup.sh|g' \
           -e 's|##DIR_HOOKS##|./'"$WORKDIR_REL"'/hooks_multistrap|g' \
              ${WORKDIR}/multistrap.conf

    # Create root filesystem
    sudo multistrap -a ${DISTRO_ARCH} -d "${IMAGE_ROOTFS}" -f "${WORKDIR}/multistrap.conf" || true

    # Configure root filesystem
    sudo chroot ${IMAGE_ROOTFS} /configscript.sh ${MACHINE_SERIAL} ${BAUDRATE_TTY} \
        ${ROOTFS_DEV}
    sudo rm ${IMAGE_ROOTFS}/configscript.sh
}

addtask rootfs before do_populate
