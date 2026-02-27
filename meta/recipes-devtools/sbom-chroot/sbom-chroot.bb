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
DEPENDS:append:bookworm = " python3-cyclonedx-lib"
DEPENDS:append:noble = " python3-cyclonedx-lib"
DEPENDS += "python3-debsbom python3-spdx-tools"

SBOM_IMAGE_INSTALL = "python3-debsbom python3-spdx-tools python3-cyclonedx-lib"

ROOTFSDIR = "${WORKDIR}/rootfs"
ROOTFS_PACKAGES = "${SBOM_IMAGE_INSTALL}"

do_sbomchroot_deploy[dirs] = "${SBOM_DIR}"
do_sbomchroot_deploy[network] = "${TASK_USE_SUDO}"
do_sbomchroot_deploy() {
    # deploy with empty var to make it smaller
    lopts="--one-file-system --exclude=var/*"
    ZSTD="zstd -${SSTATE_ZSTD_CLEVEL} -T${ZSTD_THREADS}"

    run_privileged \
        tar -C ${ROOTFSDIR} -cpS $lopts ${ROOTFS_TAR_ATTR_FLAGS} . \
            | $ZSTD > ${SBOM_CHROOT}
    # cleanup extracted rootfs
    run_privileged rm -rf ${ROOTFSDIR}
}
addtask do_sbomchroot_deploy before do_build after do_rootfs
