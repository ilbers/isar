# Root filesystem for packages building
#
# This software is a part of ISAR.
# Copyright (C) 2015-2016 ilbers GmbH

DESCRIPTION = "Isar development filesystem"

LICENSE = "gpl-2.0"
LIC_FILES_CHKSUM = "file://${LAYERDIR_isar}/licenses/COPYING.GPLv2;md5=751419260aa954499f7abaabaa882bbe"

FILESPATH_prepend := "${THISDIR}/files:"
SRC_URI = "file://configscript.sh \
           file://build.sh"
PV = "1.0"

inherit isar-bootstrap-helper

BUILDCHROOT_PREINSTALL ?= "gcc \
                           make \
                           build-essential \
                           debhelper \
                           autotools-dev \
                           dpkg \
                           locales \
                           docbook-to-man \
                           apt \
                           automake \
                           devscripts \
                           equivs"

BUILDCHROOT_PREINSTALL_WIC = " \
                             parted \
                             gdisk \
                             util-linux \
                             dosfstools \
                             mtools \
                             e2fsprogs \
                             python3"

BUILDCHROOT_PREINSTALL_WIC_append_amd64 = " \
                             syslinux \
                             syslinux-common \
                             grub-efi-amd64-bin"

BUILDCHROOT_PREINSTALL_WIC_append_armhf = " \
                             grub-efi-arm-bin"

BUILDCHROOT_PREINSTALL_WIC_append_arm64 = " \
                             grub-efi-arm64-bin"

BUILDCHROOT_PREINSTALL_WIC_append_i386 = " \
                             syslinux \
                             syslinux-common \
                             grub-efi-ia32-bin"

python () {
    if d.getVar('IMAGE_TYPE', True) == 'wic-img':
        d.appendVar('BUILDCHROOT_PREINSTALL',
                    d.getVar('BUILDCHROOT_PREINSTALL_WIC', True))
}

WORKDIR = "${TMPDIR}/work/${DISTRO}-${DISTRO_ARCH}/${PN}"

do_build[stamp-extra-info] = "${DISTRO}-${DISTRO_ARCH}"
do_build[root_cleandirs] = "${BUILDCHROOT_DIR} \
                            ${BUILDCHROOT_DIR}/isar-apt \
                            ${BUILDCHROOT_DIR}/downloads \
                            ${BUILDCHROOT_DIR}/home/builder"
do_build[depends] = "isar-apt:do_cache_config isar-bootstrap:do_deploy"

do_build() {
    setup_root_file_system "${BUILDCHROOT_DIR}" "noclean" \
        ${BUILDCHROOT_PREINSTALL}

    # Install package builder script
    sudo chmod -R a+rw "${BUILDCHROOT_DIR}/home/builder"
    sudo install -m 755 ${WORKDIR}/build.sh ${BUILDCHROOT_DIR}

    # Configure root filesystem
    sudo install -m 755 ${WORKDIR}/configscript.sh ${BUILDCHROOT_DIR}
    sudo chroot ${BUILDCHROOT_DIR} /configscript.sh
}
