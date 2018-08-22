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

IMAGE_PREINSTALL += "dbus"
IMAGE_TRANSIENT_PACKAGES += "isar-cfg-localepurge"

WORKDIR = "${TMPDIR}/work/${DISTRO}-${DISTRO_ARCH}/${PN}"

ISAR_RELEASE_CMD_DEFAULT = "git -C ${LAYERDIR_isar} describe --tags --dirty --match 'v[0-9].[0-9]*'"
ISAR_RELEASE_CMD ?= "${ISAR_RELEASE_CMD_DEFAULT}"

do_rootfs[root_cleandirs] = "${IMAGE_ROOTFS} \
                             ${IMAGE_ROOTFS}/isar-apt"

do_rootfs() {
    cat > ${WORKDIR}/fstab << EOF
# Begin /etc/fstab
/dev/${ROOTFS_DEV}	/		${ROOTFS_TYPE}		defaults		1	1
proc		/proc		proc		nosuid,noexec,nodev	0	0
sysfs		/sys		sysfs		nosuid,noexec,nodev	0	0
devpts		/dev/pts	devpts		gid=5,mode=620		0	0
tmpfs		/run		tmpfs		defaults		0	0
devtmpfs	/dev		devtmpfs	mode=0755,nosuid	0	0

# End /etc/fstab
EOF

    setup_root_file_system --clean --fstab "${WORKDIR}/fstab" \
        "${IMAGE_ROOTFS}" ${IMAGE_PREINSTALL} ${IMAGE_INSTALL}

    # Configure root filesystem
    sudo install -m 755 "${WORKDIR}/${DISTRO_CONFIG_SCRIPT}" "${IMAGE_ROOTFS}"
    sudo chroot ${IMAGE_ROOTFS} /${DISTRO_CONFIG_SCRIPT} ${MACHINE_SERIAL} \
                                                         ${BAUDRATE_TTY}

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
