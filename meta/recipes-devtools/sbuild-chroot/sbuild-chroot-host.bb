# Root filesystem for packages building
#
# This software is a part of ISAR.
# Copyright (C) 2015-2021 ilbers GmbH

DESCRIPTION = "Isar sbuild/schroot filesystem for host"

SBUILD_VARIANT = "host"

require sbuild-chroot.inc

ROOTFS_ARCH = "${HOST_ARCH}"
ROOTFS_DISTRO = "${HOST_DISTRO}"
ROOTFS_BASE_DISTRO = "${HOST_BASE_DISTRO}"

SBUILD_CHROOT_PREINSTALL ?= " \
    ${SBUILD_CHROOT_PREINSTALL_COMMON} \
    crossbuild-essential-${DISTRO_ARCH} \
    apt-utils \
    "

SBUILD_CHROOT_PREINSTALL:riscv64 ?= " \
    ${SBUILD_CHROOT_PREINSTALL_COMMON} \
    gcc-riscv64-linux-gnu \
    g++-riscv64-linux-gnu \
    dpkg-cross"
