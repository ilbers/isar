# This software is a part of ISAR.
# Copyright (C) 2021-2022 Siemens AG
#
# SPDX-License-Identifier: MIT

inherit compat
python() {
    pn = d.getVar('PN')
    archDiffers = d.getVar('HOST_ARCH') != d.getVar('DISTRO_ARCH')
    archIsAll = d.getVar('DPKG_ARCH') == 'all'

    def pn_multiarch_target(pn):
        return pn.endswith('-native') or pn.endswith('-compat')

    def extend_provides(pn, provides, d):
        if not pn_multiarch_target(pn):
            all_provides = (d.getVar('PROVIDES') or '').split()
            for p in all_provides:
                if not pn_multiarch_target(p):
                    d.appendVar('PROVIDES', f' {p}-{provides}')
            d.appendVar('PROVIDES', f' {pn}-{provides}')

    # provide compat only when we can build it
    if isar_can_build_compat(d):
        # but do not build separately if architecture-independent
        if archIsAll:
            extend_provides(pn, 'compat', d)
        else:
            d.appendVar('BBCLASSEXTEND', ' compat')

    # build native separately only when it differs from the target variant
    # We must not short-circuit for DPKG_ARCH=all packages, as they might
    # have transitive dependencies which need to be built for -native.
    if archDiffers:
        d.appendVar('BBCLASSEXTEND', ' native')
    else:
        extend_provides(pn, 'native', d)

    # drop own -native build dependencies at recipe level if building natively
    # and not for the builder architecture
    depends = d.getVar('DEPENDS')
    if depends is not None and archDiffers \
       and not bb.utils.to_boolean(d.getVar('ISAR_CROSS_COMPILE')):
        new_deps = []
        for dep in depends.split():
            if dep.endswith('-native'):
                dep = dep[:-7]
            new_deps.append(dep)
        d.setVar('DEPENDS', ' '.join(new_deps))
}

python multiarch_virtclass_handler() {
    # In compat/native builds, ${PN} includes the -compat/-native suffix,
    # so recipe-writers need to be careful when using it. Most of the time,
    # they probably want to use ${BPN}, and in general, it's their responsibility
    # to do so. If they don't, then it's ok for the build of the compat/native
    # variant to fail. However, some variables are evaluated at parse time,
    # and this will break the recipe even when compat/native is not requested.
    # e.g., SRC_URI="file://${PN}" will try to checksum the local file at
    # parse time, and parsing always happens for all build variants. So in those
    # few variables, we automatically replace ${PN} with ${BPN}.
    def fixup_pn_in_vars(d):
        v = d.getVar('SRC_URI', expand=False) or ''
        for uri in v.split():
            if '${PN}' in uri:
                d.setVar('SRC_URI' + ':remove', uri)
                d.appendVar('SRC_URI', ' ' + uri.replace('${PN}', '${BPN}'))

        v = d.getVar('FILESPATH', expand=False) or ''
        for path in v.split(':'):
            if '${PN}' in path:
                d.appendVar('FILESPATH', ':' + path.replace('${PN}', '${BPN}'))

    # When building compat/native, the corresponding suffix needs to be
    # propagated to all bitbake dependency definitions.
    def fixup_depends(suffix, d):
        vars = 'PROVIDES RPROVIDES DEPENDS RDEPENDS'.split()
        for var in vars:
            multiarch_var = []
            val = d.getVar(var)
            if val is None:
                continue
            for v in val.split():
                if v.endswith('-compat') or v.endswith('-native'):
                    multiarch_var.append(v)
                else:
                    multiarch_var.append(v + suffix)
            d.setVar(var, ' '.join(multiarch_var))

    pn = e.data.getVar('PN')
    archDiffers = d.getVar('HOST_ARCH') != d.getVar('DISTRO_ARCH')
    archIsAll = d.getVar('DPKG_ARCH') == 'all'
    if pn.endswith('-compat'):
        e.data.setVar('BPN', pn[:-len('-compat')])
        e.data.appendVar('OVERRIDES', ':class-compat')
        fixup_pn_in_vars(e.data)
        fixup_depends('-compat', e.data)
    elif pn.endswith('-native'):
        e.data.setVar('BPN', pn[:-len('-native')])
        e.data.appendVar('OVERRIDES', ':class-native')
        fixup_pn_in_vars(e.data)
        fixup_depends('-native', e.data)
    elif archIsAll and archDiffers:
        # Speed up Arch=all package build
        e.data.setVar('PACKAGE_ARCH', d.getVar('HOST_ARCH'))
}
addhandler multiarch_virtclass_handler
multiarch_virtclass_handler[eventmask] = "bb.event.RecipePreFinalise"

# function to convert bitbake targets to installable debian packages,
# e.g., "hello-compat" to "hello:i386".
def isar_multiarch_packages(var, d):
    bb_targets = (d.getVar(var) or '').split()
    packages = []
    compat_distro_arch = d.getVar('COMPAT_DISTRO_ARCH')
    host_arch = d.getVar('HOST_ARCH')
    for t in bb_targets:
        if t.endswith('-compat') and compat_distro_arch is not None:
            packages.append(t[:-len('-compat')] + ':' + compat_distro_arch)
        elif t.endswith('-native'):
            packages.append(t[:-len('-native')] + ':' + host_arch)
        else:
            packages.append(t)
    return ' '.join(packages)
