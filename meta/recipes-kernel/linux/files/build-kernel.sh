#!/bin/sh
#
# Custom kernel build
#
# This software is a part of ISAR.
# Copyright (c) Siemens AG, 2018
#
# SPDX-License-Identifier: MIT

set -e

REPACK_DIR="$1/../repack"
REPACK_LINUX_IMAGE_DIR="${REPACK_DIR}/linux-image"
REPACK_LINUX_HEADERS_DIR="${REPACK_DIR}/linux-headers"

apt-get install -y -o Debug::pkgProblemResolver=yes --no-install-recommends \
	${KBUILD_DEPENDS}

cd $1
make olddefconfig

rm -f .version
make -j $(($(nproc) * 2)) deb-pkg

rm -rf ${REPACK_DIR}
mkdir -p ${REPACK_DIR}
mkdir -p ${REPACK_LINUX_IMAGE_DIR}
mkdir -p ${REPACK_LINUX_HEADERS_DIR}

cd ..
tar xzf linux-${PV}_${PV}-1.debian.tar.gz -C ${REPACK_DIR}
dpkg-deb -R linux-image-${PV}_${PV}-1_*.deb ${REPACK_LINUX_IMAGE_DIR}
dpkg-deb -R linux-headers-${PV}_${PV}-1_*.deb ${REPACK_LINUX_HEADERS_DIR}

dpkg-gencontrol -crepack/debian/control \
	-lrepack/debian/changelog \
	-frepack/debian/files \
	-plinux-image-${PV} \
	-P${REPACK_LINUX_IMAGE_DIR} \
	-DPackage="linux-image-${KERNEL_NAME}" \
	-DSection=kernel \
	-DPriority=required \
	-DDepends="${KERNEL_DEBIAN_DEPENDS}"

# Add Debian-like link installation to postinst
touch ${REPACK_LINUX_IMAGE_DIR}/lib/modules/${PV}/.fresh-install
sed -i ${REPACK_LINUX_IMAGE_DIR}/DEBIAN/postinst \
    -e "/^set -e$/a\\
\\
if [ -f /lib/modules/${PV}/.fresh-install ]; then\\
	change=install\\
else\\
	change=upgrade\\
fi\\
linux-update-symlinks \$change ${PV} /boot/vmlinuz-${PV}\\
rm -f /lib/modules/${PV}/.fresh-install"

# Add Debian-like link removal to postrm
sed -i ${REPACK_LINUX_IMAGE_DIR}/DEBIAN/postrm \
    -e "/^set -e$/a\\
\\
rm -f /lib/modules/${PV}/.fresh-install\\
\\
if [ \"\$1\" != upgrade ] && command -v linux-update-symlinks >/dev/null; then\\
	linux-update-symlinks remove ${PV}  /boot/vmlinuz-${PV}\\
fi"

dpkg-gencontrol -crepack/debian/control \
	-lrepack/debian/changelog \
	-frepack/debian/files \
	-plinux-headers-${PV} \
	-P${REPACK_LINUX_HEADERS_DIR} \
	-Vkernel:debarch="${KERNEL_NAME}" \
	-DPackage="linux-headers-${KERNEL_NAME}" \
	-DSection=kernel \
	-DDepends="${KERNEL_HEADERS_DEBIAN_DEPENDS}"

dpkg-deb -b ${REPACK_LINUX_IMAGE_DIR} \
	linux-image-${KERNEL_NAME}_${PV}-1_${KERNEL_NAME}.deb
rm -f linux-image-${PV}_${PV}-1_*.deb
dpkg-deb -b ${REPACK_LINUX_HEADERS_DIR} \
	linux-headers-${KERNEL_NAME}_${PV}-1_${KERNEL_NAME}.deb
rm -f linux-headers-${PV}_${PV}-1_*.deb
