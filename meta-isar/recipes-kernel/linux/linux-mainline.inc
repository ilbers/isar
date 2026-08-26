# Example recipe for building the mainline kernel
#
# This software is a part of Isar.
# Copyright (c) Siemens AG, 2026
#
# SPDX-License-Identifier: MIT

inherit linux-kernel

ARCHIVE_VERSION = "${@ d.getVar('PV')[:-2] if d.getVar('PV').endswith('.0') else d.getVar('PV') }"

SRC_URI += " \
    https://cdn.kernel.org/pub/linux/kernel/v6.x/linux-${ARCHIVE_VERSION}.tar.xz \
    file://ftpm-module.cfg \
    file://subdir \
    file://no-root-nfs.cfg;apply=no"

SRC_URI[sha256sum] = "f143aaade8877ba5616e788b4482576db28481bcf557ef537f4fcc3938fc3176"

S = "${WORKDIR}/linux-${ARCHIVE_VERSION}"

SRC_URI:append:amd64 = " file://${KERNEL_DEFCONFIG}"
KERNEL_DEFCONFIG:amd64 = "x86_64_defconfig"

LINUX_VERSION_EXTENSION = "-isar"

KERNEL_CONFIG_FRAGMENTS = "subdir/no-ubifs-fs.cfg"

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
