# This software is a part of Isar.
# Copyright (C) 2023-2024 ilbers GmbH
# Copyright (C) 2023-2024 Siemens AG
#
# SPDX-License-Identifier: MIT

ISAR_CROSS_COMPILE ??= "1"

inherit compat

python __anonymous() {
    import pwd
    d.setVar('SCHROOT_USER', pwd.getpwuid(os.geteuid()).pw_name)

    mode = bb.utils.to_boolean(d.getVar('ISAR_CROSS_COMPILE'))

    # support derived schroots
    flavor = d.getVar('SBUILD_FLAVOR')
    flavor_suffix = ('-' + flavor) if flavor else ''

    distro_arch = d.getVar('DISTRO_ARCH')
    compat_arch = d.getVar('COMPAT_DISTRO_ARCH')
    host_arch = d.getVar('HOST_ARCH')
    package_arch = d.getVar('PACKAGE_ARCH')

    if distro_arch != host_arch and \
        (package_arch == host_arch or \
         (package_arch in [distro_arch, compat_arch, '${BUILD_ARCH}'] and mode)):
        d.setVar('BUILD_ARCH', host_arch)
        schroot_dir = d.getVar('SCHROOT_HOST_DIR', False)
        sbuild_dep = "sbuild-chroot-host" + flavor_suffix + ":do_build"
        sdk_toolchain = "crossbuild-essential-" + distro_arch
        schroot_base_distro = d.getVar('HOST_BASE_DISTRO', False)
    else:
        d.setVar('BUILD_ARCH', distro_arch)
        schroot_dir = d.getVar('SCHROOT_TARGET_DIR', False)
        sbuild_dep = "sbuild-chroot-target" + flavor_suffix + ":do_build"
        sdk_toolchain = "build-essential"
        schroot_base_distro = d.getVar('BASE_DISTRO', False)
    d.setVar('SCHROOT_DIR', schroot_dir + flavor_suffix)
    d.setVar('SCHROOT_DEP', sbuild_dep)
    # BASE_DISTRO is resolved against OVERRIDES, which start with PACKAGE_ARCH,
    # so it does not describe the chroot a recipe is built in (PACKAGE_ARCH is
    # HOST_ARCH for native recipes). Mirror ROOTFS_BASE_DISTRO of the
    # sbuild-chroot recipes to give the DEBDIR/DEBSRCDIR layout a single,
    # chroot-correct name.
    d.setVar('SCHROOT_BASE_DISTRO', schroot_base_distro)
    if isar_can_build_compat(d):
        sdk_toolchain += " crossbuild-essential-" + compat_arch
    d.setVar('SDK_TOOLCHAIN', sdk_toolchain)
}
