# This software is a part of Isar.
#
# Copyright (C) 2026 Siemens

LICENSE = "gpl-2.0"
LIC_FILES_CHKSUM = "file://${LAYERDIR_core}/licenses/COPYING.GPLv2;md5=751419260aa954499f7abaabaa882bbe"

PV = "1.0"

inherit rootfs
inherit host-tooling

ROOTFS_ARCH = "${HOST_ARCH}"
ROOTFS_DISTRO = "${@get_rootfs_distro(d)}"
ROOTFS_BASE_DISTRO = "${HOST_BASE_DISTRO}"

ROOTFS_FEATURES:remove = "generate-initrd"
ROOTFS_INSTALL_COMMAND:remove = "rootfs_restore_initrd_tooling"

DEPENDS += "${HOST_TOOLING_DEPENDS}"
ROOTFSDIR = "${WORKDIR}/rootfs"
ROOTFS_PACKAGES += "${HOST_TOOLING_PACKAGES}"

inherit rootfs-deploy

ROOTFS_TAR_FLAGS = "--exclude=var/*"
ROOTFS_DEPLOY_DIR = "${HOST_TOOLING_DEPLOY_DIR}"
ROOTFS_DEPLOY_FILE = "${HOST_TOOLING_CHROOT}"
