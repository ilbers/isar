# Root filesystem for packages building
#
# This software is a part of ISAR.
# Copyright (C) 2015-2018 ilbers GmbH

DESCRIPTION = "Isar development filesystem for target"

include buildchroot.inc

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

do_build[depends] = "isar-apt:do_cache_config isar-bootstrap-target:do_bootstrap"
