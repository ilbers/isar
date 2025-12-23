# This software is a part of ISAR.
#
# Copyright (C) 2025 Siemens

LICENSE = "gpl-2.0"
LIC_FILES_CHKSUM = "file://${LAYERDIR_core}/licenses/COPYING.GPLv2;md5=751419260aa954499f7abaabaa882bbe"

PV = "1.0"

inherit rootfs

ROOTFS_ARCH = "${HOST_ARCH}"
ROOTFS_DISTRO = "${@get_rootfs_distro(d)}"
ROOTFS_BASE_DISTRO = "${HOST_BASE_DISTRO}"

ROOTFS_FEATURES:remove = "generate-initrd"
ROOTFS_INSTALL_COMMAND:remove = "rootfs_restore_initrd_tooling"

# additional packages for the SBOM chroot
SBOM_IMAGE_INSTALL = "python3-debsbom"
DEPENDS += "python3-debsbom"

ROOTFSDIR = "${WORKDIR}/rootfs"
ROOTFS_PACKAGES = "${SBOM_IMAGE_INSTALL}"

do_sbomchroot_deploy[dirs] = "${SBOM_DIR}"
do_sbomchroot_deploy() {
    ln -Tfsr "${ROOTFSDIR}" "${SBOM_CHROOT}"
}
addtask do_sbomchroot_deploy before do_build after do_rootfs
