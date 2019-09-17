# Custom kernel build
#
# This software is a part of ISAR.
# Copyright (c) Siemens AG, 2018
#
# SPDX-License-Identifier: MIT

FILESPATH =. "${LAYERDIR_core}/recipes-kernel/linux/files:"

DESCRIPTION ?= "Custom kernel"

KERNEL_NAME_PROVIDED ?= "${@ d.getVar('PN', True).partition('linux-')[2]}"
KERNEL_DEFCONFIG ?= ""

python() {
    kernel_name = d.getVar("KERNEL_NAME_PROVIDED", True)
    d.setVar('PROVIDES', 'linux-image-' + kernel_name + ' ' + \
                         'linux-headers-' + kernel_name)
}

inherit dpkg-base

SRC_URI += "file://build-kernel.sh"

KBUILD_DEPENDS ?= " \
    build-essential:native \
    libssl-dev \
    libelf-dev \
    bc \
    git \
    kmod \
    bison \
    flex \
    cpio \
    libncurses-dev"
KERNEL_DEBIAN_DEPENDS ?= "initramfs-tools | linux-initramfs-tool, kmod, linux-base (>= 4.3~)"
KERNEL_HEADERS_DEBIAN_DEPENDS ?= "libc6, libssl1.1"

KERNEL_LIBC_DEV_DEPLOY ?= "0"

do_install_builddeps() {
	dpkg_do_mounts
	E="${@ bb.utils.export_proxies(d)}"
	sudo -E chroot ${BUILDCHROOT_DIR} \
		apt-get update \
			-o Dir::Etc::SourceList="sources.list.d/isar-apt.list" \
			-o Dir::Etc::SourceParts="-" \
			-o APT::Get::List-Cleanup="0"
	sudo -E chroot ${BUILDCHROOT_DIR} \
		apt-get install \
			-y -o Debug::pkgProblemResolver=yes \
			--no-install-recommends ${KBUILD_DEPENDS}
	dpkg_undo_mounts
}

addtask install_builddeps after do_prepare_build before do_dpkg_build
# apt and reprepro may not run in parallel, acquire the Isar lock
do_install_builddeps[lockfiles] += "${REPO_ISAR_DIR}/isar.lock"

addtask devshell after do_install_builddeps

dpkg_runbuild() {
	chmod +x ${WORKDIR}/build-kernel.sh
	if [ -n "${KERNEL_DEFCONFIG}" ]; then
		cp ${WORKDIR}/${KERNEL_DEFCONFIG} ${S}/.config
	fi

	E="${@ bb.utils.export_proxies(d)}"

	export PV=${PV}
	export KERNEL_NAME=${KERNEL_NAME_PROVIDED}

	export KBUILD_DEPENDS="${KBUILD_DEPENDS}"
	export KERNEL_DEBIAN_DEPENDS="${KERNEL_DEBIAN_DEPENDS}"
	export KERNEL_HEADERS_DEBIAN_DEPENDS="${KERNEL_HEADERS_DEBIAN_DEPENDS}"

	sudo -E chroot --userspec=$( id -u ):$( id -g ) ${BUILDCHROOT_DIR} ${PP}/build-kernel.sh ${PP}/${PPS} ${DISTRO_ARCH}

	if [ "${KERNEL_LIBC_DEV_DEPLOY}" != "1" ]; then
		rm -f ${WORKDIR}/linux-libc-dev_${PV}*.deb
	fi
}
