# Custom kernel build
#
# This software is a part of ISAR.
# Copyright (c) Siemens AG, 2018
#
# SPDX-License-Identifier: MIT

FILESPATH =. "${LAYERDIR_core}/recipes-kernel/linux/files:"

DESCRIPTION ?= "Custom kernel"

KERNEL_FLAVOR ?= "${@ d.getVar('PN', True).partition('linux-')[2]}"
KERNEL_DEFCONFIG ?= "defconfig"

python() {
    kernel = d.getVar("KERNEL_NAME", True)
    flavor = d.getVar("KERNEL_FLAVOR", True)
    if kernel and flavor and kernel.startswith(flavor + "-"):
        d.setVar('PROVIDES', 'linux-image-' + kernel + ' ' + \
                             'linux-headers-' + kernel)
}

inherit dpkg-base

SRC_URI += "file://build-kernel.sh"

KBUILD_DEPENDS ?= "libssl-dev libelf-dev bc"
KERNEL_DEBIAN_DEPENDS ?= "initramfs-tools | linux-initramfs-tool, kmod, linux-base (>= 4.3~)"
KERNEL_HEADERS_DEBIAN_DEPENDS ?= "libc6, libssl1.1, gcc"

dpkg_runbuild() {
	# Install package builder script
	sudo install -m 755 ${WORKDIR}/build-kernel.sh ${BUILDCHROOT_DIR}

	sudo cp ${WORKDIR}/${KERNEL_DEFCONFIG} ${S}/.config

	E="${@ bb.utils.export_proxies(d)}"

	export PV=${PV}
	export KERNEL_NAME=${KERNEL_NAME}

	export KBUILD_DEPENDS="${KBUILD_DEPENDS}"
	export KERNEL_DEBIAN_DEPENDS="${KERNEL_DEBIAN_DEPENDS}"
	export KERNEL_HEADERS_DEBIAN_DEPENDS="${KERNEL_HEADERS_DEBIAN_DEPENDS}"

	sudo -E chroot ${BUILDCHROOT_DIR} /build-kernel.sh ${PP}/${PPS} ${DISTRO_ARCH}
}
