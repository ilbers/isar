# Root filesystem for packages building
#
# This software is a part of ISAR.
# Copyright (C) 2015-2018 ilbers GmbH

DESCRIPTION = "Isar development filesystem for host"
PF = "${PN}-${HOST_DISTRO}-${HOST_ARCH}-${DISTRO_ARCH}"

require buildchroot.inc
ROOTFS_ARCH = "${HOST_ARCH}"
ROOTFS_DISTRO = "${HOST_DISTRO}"

BUILDCHROOT_PREINSTALL ?= "make \
                           debhelper \
                           autotools-dev \
                           dpkg \
                           locales \
                           docbook-to-man \
                           apt \
                           automake \
                           devscripts \
                           equivs \
                           libc6:${DISTRO_ARCH} \
                           crossbuild-essential-${DISTRO_ARCH}"
