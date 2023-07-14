# Root filesystem for packages building
#
# This software is a part of ISAR.
# Copyright (C) 2015-2021 ilbers GmbH

DESCRIPTION = "Isar sbuild/schroot filesystem for target"

SBUILD_VARIANT = "target"

require sbuild-chroot.inc

SBUILD_CHROOT_PREINSTALL ?= " \
    ${SBUILD_CHROOT_PREINSTALL_COMMON} \
    ${@' apt-utils' if d.getVar('ISAR_ENABLE_COMPAT_ARCH') == '1' else ''} \
    "
