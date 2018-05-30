# Root filesystem for target installation
#
# This software is a part of ISAR.
# Copyright (C) 2015-2017 ilbers GmbH

DESCRIPTION = "Isar target filesystem"

LICENSE = "gpl-2.0"
LIC_FILES_CHKSUM = "file://${LAYERDIR_isar}/licenses/COPYING.GPLv2;md5=751419260aa954499f7abaabaa882bbe"

FILESPATH =. "${LAYERDIR_isar}/recipes-core/images/files:"
SRC_URI = "file://${DISTRO_CONFIG_SCRIPT}"

PV = "1.0"

inherit image
inherit isar-bootstrap-helper

DEPENDS += "${IMAGE_INSTALL} ${IMAGE_TRANSIENT_PACKAGES}"

IMAGE_PREINSTALL += "apt \
                     dbus"
IMAGE_TRANSIENT_PACKAGES += "isar-cfg-localepurge"

WORKDIR = "${TMPDIR}/work/${DISTRO}-${DISTRO_ARCH}/${PN}"

do_rootfs[root_cleandirs] = "${IMAGE_ROOTFS} \
                             ${IMAGE_ROOTFS}/isar-apt"

do_rootfs() {
    setup_root_file_system "${IMAGE_ROOTFS}" "clean" \
        ${IMAGE_PREINSTALL} ${IMAGE_INSTALL}

    # Configure root filesystem
    sudo install -m 755 "${WORKDIR}/${DISTRO_CONFIG_SCRIPT}" "${IMAGE_ROOTFS}"
    sudo chroot ${IMAGE_ROOTFS} /${DISTRO_CONFIG_SCRIPT} ${MACHINE_SERIAL} \
                                                         ${BAUDRATE_TTY} \
                                                         ${ROOTFS_DEV} \
                                                         ${ROOTFS_TYPE}

    # Cleanup
    sudo rm "${IMAGE_ROOTFS}/${DISTRO_CONFIG_SCRIPT}"
    sudo rm "${IMAGE_ROOTFS}/etc/apt/sources.list.d/isar-apt.list"
    test ! -e "${IMAGE_ROOTFS}/usr/share/doc/qemu-user-static" && \
         sudo find "${IMAGE_ROOTFS}/usr/bin" \
              -maxdepth 1 -name 'qemu-*-static' -type f -delete
    sudo umount -l ${IMAGE_ROOTFS}/isar-apt
    sudo rmdir ${IMAGE_ROOTFS}/isar-apt
    sudo umount -l ${IMAGE_ROOTFS}/dev
    sudo umount -l ${IMAGE_ROOTFS}/proc
    sudo rm -f "${IMAGE_ROOTFS}/etc/apt/apt.conf.d/55isar-fallback.conf"
}
