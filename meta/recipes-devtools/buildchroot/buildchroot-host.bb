# Root filesystem for packages building
#
# This software is a part of ISAR.
# Copyright (C) 2015-2018 ilbers GmbH

DESCRIPTION = "Isar development filesystem for host"

BUILDCHROOT_VARIANT = "host"

require buildchroot.inc
ROOTFS_ARCH = "${HOST_ARCH}"
ROOTFS_DISTRO = "${HOST_DISTRO}"

BUILDCHROOT_PREINSTALL ?= " \
    ${BUILDCHROOT_PREINSTALL_COMMON} \
    libc6:${DISTRO_ARCH} \
    crossbuild-essential-${DISTRO_ARCH}"
