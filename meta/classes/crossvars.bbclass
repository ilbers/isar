# This software is a part of ISAR.
# Copyright (C) 2022 ilbers GmbH

ISAR_CROSS_COMPILE ??= "0"

inherit compat

python __anonymous() {
    import pwd
    d.setVar('SCHROOT_USER', pwd.getpwuid(os.geteuid()).pw_name)

    mode = d.getVar('ISAR_CROSS_COMPILE')
    distro_arch = d.getVar('DISTRO_ARCH')
    if mode == "0" or d.getVar('HOST_ARCH') == distro_arch or distro_arch == None:
        d.setVar('BUILD_HOST_ARCH', distro_arch)
        schroot_dir = d.getVar('SCHROOT_TARGET_DIR', False)
        sbuild_dep = "sbuild-chroot-target:do_build"
        buildchroot_dir = d.getVar('BUILDCHROOT_TARGET_DIR', False)
        buildchroot_dep = "buildchroot-target:do_build"
        sdk_toolchain = "build-essential"
    else:
        d.setVar('BUILD_HOST_ARCH', d.getVar('HOST_ARCH'))
        schroot_dir = d.getVar('SCHROOT_HOST_DIR', False)
        sbuild_dep = "sbuild-chroot-host:do_build"
        buildchroot_dir = d.getVar('BUILDCHROOT_HOST_DIR', False)
        buildchroot_dep = "buildchroot-host:do_build"
        sdk_toolchain = "crossbuild-essential-" + distro_arch
    d.setVar('SCHROOT_DIR', schroot_dir)
    d.setVar('SCHROOT_DEP', sbuild_dep)
    d.setVar('BUILDCHROOT_DIR', buildchroot_dir)
    d.setVar('BUILDCHROOT_DEP', buildchroot_dep)
    if isar_can_build_compat(d):
        sdk_toolchain += " crossbuild-essential-" + d.getVar('COMPAT_DISTRO_ARCH')
    d.setVar('SDK_TOOLCHAIN', sdk_toolchain)
}
