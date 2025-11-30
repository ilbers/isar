# This software is a part of ISAR.
# Copyright (C) 2023 Siemens AG
#
# SPDX-License-Identifier: MIT

# this class is "dual-use": it can be inherited (e.g., by bootstrap and image
# classes) to access variables and functions, and it's also added via BBCLASSEXTEND
# when inheriting multiconfig.bbclass.

################################################################################
# generic functions
################################################################################

# determine COMPAT_DISTRO_ARCH and ISAR_ENABLE_COMPAT_ARCH
# this must always use the DISTRO_ARCH override (not PACKAGE_ARCH), so needs
# to happen in a modified environment
python() {
    distro_arch = d.getVar('DISTRO_ARCH')
    package_arch = d.getVar('PACKAGE_ARCH')
    overrides = d.getVar('OVERRIDES').split(':')

    localdata = bb.data.createCopy(d)
    new_overrides = [distro_arch] + [o for o in overrides if not o == package_arch]
    localdata.setVar('OVERRIDES', ':'.join(new_overrides))
    isar_enable_compat_arch = localdata.getVar('ISAR_ENABLE_COMPAT_ARCH')
    compat_distro_arch = localdata.getVar('COMPAT_DISTRO_ARCH')

    d.setVar('COMPAT_DISTRO_ARCH', compat_distro_arch)
    d.setVar('ISAR_ENABLE_COMPAT_ARCH', isar_enable_compat_arch)
}

def isar_can_build_compat(d):
    return (d.getVar('COMPAT_DISTRO_ARCH') is not None and
        bb.utils.to_boolean(d.getVar('ISAR_ENABLE_COMPAT_ARCH')))

################################################################################
# package recipe modifications when building *-compat:
################################################################################

PACKAGE_ARCH:class-compat = "${COMPAT_DISTRO_ARCH}"
