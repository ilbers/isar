# Example recipe for building the mainline kernel
#
# This software is a part of ISAR.
# Copyright (c) Siemens AG, 2018-2020
#
# SPDX-License-Identifier: MIT

require recipes-kernel/linux/linux-custom.inc

ARCHIVE_VERSION = "${@ d.getVar('PV')[:-2] if d.getVar('PV').endswith('.0') else d.getVar('PV') }"

SRC_URI += " \
    https://cdn.kernel.org/pub/linux/kernel/v5.x/linux-${ARCHIVE_VERSION}.tar.xz \
    file://x86_64_defconfig \
    file://no-ubifs-fs.cfg \
    file://no-root-nfs.cfg;apply=no"

SRC_URI[sha256sum] = "c0b3d8085c5ba235df38b00b740e053659709e8a5ca21957a239f6bc22c45007"

S = "${WORKDIR}/linux-${ARCHIVE_VERSION}"

KERNEL_DEFCONFIG_qemuamd64 = "x86_64_defconfig"

LINUX_VERSION_EXTENSION = "-isar"

# For testing purposes only
dpkg_configure_kernel_append() {
    if ! grep "# CONFIG_MTD is not set" ${S}/${KERNEL_BUILD_DIR}/.config && \
       ! grep "# CONFIG_MTD_UBI is not set" ${S}/${KERNEL_BUILD_DIR}/.config; then
        grep "# CONFIG_UBIFS_FS is not set" ${S}/${KERNEL_BUILD_DIR}/.config || \
            bbfatal "Self-check failed: CONFIG_UBIFS_FS still enabled"
    fi
    grep "CONFIG_ROOT_NFS=y" ${S}/${KERNEL_BUILD_DIR}/.config || \
        bbfatal "Self-check failed: CONFIG_ROOT_NFS not enabled"
}
