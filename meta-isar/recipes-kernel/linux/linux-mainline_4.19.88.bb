# Example recipe for building the mainline kernel
#
# This software is a part of ISAR.
# Copyright (c) Siemens AG, 2018
#
# SPDX-License-Identifier: MIT

require recipes-kernel/linux/linux-custom.inc

ARCHIVE_VERSION = "${@ d.getVar('PV')[:-2] if d.getVar('PV').endswith('.0') else d.getVar('PV') }"

SRC_URI += " \
    https://cdn.kernel.org/pub/linux/kernel/v4.x/linux-${ARCHIVE_VERSION}.tar.xz \
    file://x86_64_defconfig \
    file://no-ubifs-fs.cfg \
    file://no-root-nfs.cfg;apply=no"

SRC_URI[sha256sum] = "c1923b6bd166e6dd07be860c15f59e8273aaa8692bc2a1fce1d31b826b9b3fbe"

SRC_URI_append_de0-nano-soc = " \
    file://0001-ARM-dts-socfpga-Rename-socfpga_cyclone5_de0_-sockit-.patch"

S = "${WORKDIR}/linux-${ARCHIVE_VERSION}"

KERNEL_DEFCONFIG_qemuamd64 = "x86_64_defconfig"

LINUX_VERSION_EXTENSION = "-isar"

# For testing purposes only
dpkg_configure_kernel_append() {
    grep "# CONFIG_UBIFS_FS is not set" ${S}/${KERNEL_BUILD_DIR}/.config || \
        bbfatal "Self-check failed: CONFIG_UBIFS_FS still enabled"
    grep "CONFIG_ROOT_NFS=y" ${S}/${KERNEL_BUILD_DIR}/.config || \
        bbfatal "Self-check failed: CONFIG_ROOT_NFS not enabled"
}
