# Root filesystem for target installation
#
# This software is a part of ISAR.
# Copyright (C) 2015-2017 ilbers GmbH

DESCRIPTION = "Multistrap target filesystem"

LICENSE = "gpl-2.0"
LIC_FILES_CHKSUM = "file://${LAYERDIR_isar}/licenses/COPYING.GPLv2;md5=751419260aa954499f7abaabaa882bbe"

FILESPATH =. "${LAYERDIR_isar}/recipes-core/images/files:"
SRC_URI = "file://multistrap.conf.in \
	   file://${DISTRO_CONFIG_SCRIPT} \
	   file://setup.sh \
	   file://download_dev-random"

PV = "1.0"

inherit image

DEPENDS += "${IMAGE_INSTALL}"

IMAGE_PREINSTALL += "apt \
                     dbus \
                     localepurge"

WORKDIR = "${TMPDIR}/work/${DISTRO}-${DISTRO_ARCH}/${PN}"

do_rootfs[stamp-extra-info] = "${MACHINE}-${DISTRO}"
do_rootfs[dirs] = "${WORKDIR}/hooks_multistrap"

do_rootfs() {
    chmod +x "${WORKDIR}/${DISTRO_CONFIG_SCRIPT}"
    chmod +x "${WORKDIR}/setup.sh"
    install -m 755 "${WORKDIR}/download_dev-random" "${WORKDIR}/hooks_multistrap/"

    # Multistrap accepts only relative path in configuration files, so get it:
    cd ${TOPDIR}
    WORKDIR_REL=${@ os.path.relpath(d.getVar("WORKDIR", True))}

    # Adjust multistrap config
    sed -e 's|##IMAGE_PREINSTALL##|${IMAGE_PREINSTALL}|g' \
        -e 's|##DISTRO##|${DISTRO}|g' \
        -e 's|##DISTRO_APT_SOURCE##|${DISTRO_APT_SOURCE}|g' \
        -e 's|##DISTRO_SUITE##|${DISTRO_SUITE}|g' \
        -e 's|##DISTRO_COMPONENTS##|${DISTRO_COMPONENTS}|g' \
        -e 's|##CONFIG_SCRIPT##|./'"$WORKDIR_REL"'/${DISTRO_CONFIG_SCRIPT}|g' \
        -e 's|##SETUP_SCRIPT##|./'"$WORKDIR_REL"'/setup.sh|g' \
        -e 's|##DIR_HOOKS##|./'"$WORKDIR_REL"'/hooks_multistrap|g' \
        -e 's|##IMAGE_INSTALL##|${IMAGE_INSTALL}|g' \
        -e 's|##DEPLOY_DIR_APT##|copy:///${DEPLOY_DIR_APT}/${DISTRO}|g' \
        -e 's|##ISAR_DISTRO_SUITE##|${DEBDISTRONAME}|g' \
           "${WORKDIR}/multistrap.conf.in" > "${WORKDIR}/multistrap.conf"

    [ ! -d ${IMAGE_ROOTFS}/proc ] && sudo install -d -o 0 -g 0 -m 555 ${IMAGE_ROOTFS}/proc
    sudo mount -t proc none ${IMAGE_ROOTFS}/proc
    _do_rootfs_cleanup() {
        ret=$?
        sudo umount ${IMAGE_ROOTFS}/proc 2>/dev/null || true
        (exit $ret) || bb_exit_handler
    }
    trap '_do_rootfs_cleanup' EXIT

    # Create root filesystem
    sudo multistrap -a ${DISTRO_ARCH} -d "${IMAGE_ROOTFS}" -f "${WORKDIR}/multistrap.conf"

    # Configure root filesystem
    sudo chroot ${IMAGE_ROOTFS} /${DISTRO_CONFIG_SCRIPT} ${MACHINE_SERIAL} ${BAUDRATE_TTY} \
        ${ROOTFS_DEV}
    sudo rm "${IMAGE_ROOTFS}/${DISTRO_CONFIG_SCRIPT}"
    _do_rootfs_cleanup
}

addtask rootfs before do_build after do_populate
