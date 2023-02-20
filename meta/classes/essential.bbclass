# This software is a part of ISAR.
# Copyright (C) 2023 Siemens AG

ISAR_REBUILD_ESSENTIAL_PKGS ?= ""

python() {
    isar_rebuild_essential_pkgs = (d.getVar('ISAR_REBUILD_ESSENTIAL_PKGS') or '').split()
    build_compat = d.getVar('ISAR_ENABLE_COMPAT_ARCH') == "1"
    build_native = not d.getVar('DISTRO_ARCH') == d.getVar('HOST_ARCH')

    # construct list of essential packages that should be rebuilt:
    # if we can't build compat, don't include any -compat packages
    # if we don't need native (because DISTRO_ARCH == HOST_ARCH), don't build native
    # otherwise, automatically include compat/native when we can build them
    essential_packages = []
    for p in isar_rebuild_essential_pkgs:
        if p.endswith('-compat') and build_compat:
            essential_packages.append(p)
        elif p.endswith('-native') and build_native:
            essential_packages.append(p)
        else:
            essential_packages.append(p)
            if build_compat:
                essential_packages.append(f'{p}-compat')
            if build_native:
                essential_packages.append(f'{p}-native')

    # bail out if this recipe is in the essential list
    if d.getVar('PN') in essential_packages:
        return

    # add dependencies to all packages from the essential list
    for p in essential_packages:
        if d.getVar('do_prepare_build'):
            d.appendVarFlag('do_prepare_build', 'depends', f' {p}:do_deploy_deb')
        if d.getVar('do_install_rootfs'):
            d.appendVarFlag('do_install_rootfs', 'depends', f' {p}:do_deploy_deb')
}
