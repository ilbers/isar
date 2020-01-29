# Example recipe for building the mainline kernel
#
# This software is a part of ISAR.
# Copyright (c) Siemens AG, 2018
#
# SPDX-License-Identifier: MIT

require recipes-kernel/linux/linux-custom.inc

ARCHIVE_VERSION = "${@ d.getVar('PV')[:-2] if d.getVar('PV').endswith('.0') else d.getVar('PV') }"

SRC_URI += " \
    https://cdn.kernel.org/pub/linux/kernel/v5.x/linux-${ARCHIVE_VERSION}.tar.xz \
    file://x86_64_defconfig \
    file://no-ubifs-fs.cfg \
    file://no-root-nfs.cfg;apply=no"

SRC_URI[sha256sum] = "f23c0218a5e3b363bb5a880972f507bb4dc4a290a787a7da08be07ea12042edd"

S = "${WORKDIR}/linux-${ARCHIVE_VERSION}"

KERNEL_DEFCONFIG_qemuamd64 = "x86_64_defconfig"

LINUX_VERSION_EXTENSION = "-isar"

# For testing purposes only
dpkg_configure_kernel_append() {
    if ! grep "# CONFIG_MTD is not set" ${S}/${KERNEL_BUILD_DIR}/.config; then
        grep "# CONFIG_UBIFS_FS is not set" ${S}/${KERNEL_BUILD_DIR}/.config || \
            bbfatal "Self-check failed: CONFIG_UBIFS_FS still enabled"
    fi
    grep "CONFIG_ROOT_NFS=y" ${S}/${KERNEL_BUILD_DIR}/.config || \
        bbfatal "Self-check failed: CONFIG_ROOT_NFS not enabled"
}
