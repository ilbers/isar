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
cat << EOF | sed -i '/^override_dh_auto_build/ r /dev/stdin' ${S}/debian/rules
	if ! grep "# CONFIG_MTD is not set" \$(O)/.config && \\
	   ! grep "# CONFIG_MTD_UBI is not set" \$(O)/.config; then \\
	    grep "# CONFIG_UBIFS_FS is not set" \$(O)/.config || \\
	        (echo "Self-check failed: CONFIG_UBIFS_FS still enabled" && exit 1); \\
	fi
	grep "CONFIG_ROOT_NFS=y" \$(O)/.config || \\
	    (echo "Self-check failed: CONFIG_ROOT_NFS not enabled" && exit 1)
EOF
}
