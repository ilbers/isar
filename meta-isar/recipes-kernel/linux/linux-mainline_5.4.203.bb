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
    file://ftpm-module.cfg \
    file://no-ubifs-fs.cfg \
    file://no-root-nfs.cfg;apply=no"

SRC_URI[sha256sum] = "fc933f5b13066cfa54aacb5e86747a167bad1d8d23972e4a03ab5ee36c29798a"

S = "${WORKDIR}/linux-${ARCHIVE_VERSION}"

KERNEL_DEFCONFIG:qemuamd64 = "x86_64_defconfig"

LINUX_VERSION_EXTENSION = "-isar"

# For testing purposes only
dpkg_configure_kernel:append() {
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
