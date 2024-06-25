# Example recipe for building the mainline kernel
#
# This software is a part of ISAR.
# Copyright (c) Siemens AG, 2018-2024
#
# SPDX-License-Identifier: MIT

require recipes-kernel/linux/linux-custom.inc

ARCHIVE_VERSION = "${@ d.getVar('PV')[:-2] if d.getVar('PV').endswith('.0') else d.getVar('PV') }"

SRC_URI += " \
    https://cdn.kernel.org/pub/linux/kernel/v6.x/linux-${ARCHIVE_VERSION}.tar.xz \
    file://x86_64_defconfig \
    file://ftpm-module.cfg \
    file://subdir/no-ubifs-fs.cfg \
    file://no-root-nfs.cfg;apply=no"

SRC_URI[sha256sum] = "afe2e5a661bb886d762684ebea71607d1ee8cb9dd100279d2810ba20d9671e52"

S = "${WORKDIR}/linux-${ARCHIVE_VERSION}"

KERNEL_DEFCONFIG:qemuamd64 = "x86_64_defconfig"

LINUX_VERSION_EXTENSION = "-isar"

check_fragments_applied() {
    grep -q "# CONFIG_MTD is not set" ${S}/debian/rules ||
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

# For testing purposes only
dpkg_configure_kernel:append() {
    check_fragments_applied
}
