# Common part for build chroot filesystem.
#
# This software is a part of ISAR.
# Copyright (C) 2015-2021 ilbers GmbH

LICENSE = "gpl-2.0"
LIC_FILES_CHKSUM = "file://${LAYERDIR_core}/licenses/COPYING.GPLv2;md5=751419260aa954499f7abaabaa882bbe"

PV = "1.0"

python __anonymous() {
    distro_arch = d.getVar('DISTRO_ARCH')
    host_arch = d.getVar('HOST_ARCH')
    variant = d.getVar('SBUILD_VARIANT', True)

    if variant == "target" or host_arch ==  distro_arch:
        d.setVar('DEBREPO_WORKDIR', d.getVar('DEBREPO_TARGET_DIR', True))
    else:
        d.setVar('DEBREPO_WORKDIR', d.getVar('DEBREPO_HOST_DIR', True))
}

inherit rootfs
inherit compat

# set the flavor to create derived sbuild chroots
# this maps to a schroot created by a recipe named sbuild-chroot-<host|target>-<flavor>
SBUILD_FLAVOR ??= ""
SBUILD_SCHROOT_SUFFIX = "${@ ('-' + d.getVar('SBUILD_FLAVOR')) if d.getVar('SBUILD_FLAVOR') else ''}"
SBUILD_CHROOT_PREINSTALL_EXTRA ??= ""

python() {
    distro_gcc = d.getVar('DISTRO_GCC')
    distro_arch = d.getVar('DISTRO_ARCH')

    if d.getVar('DISTRO_GCC'):
        d.appendVar('SBUILD_CHROOT_PREINSTALL_COMMON',
                    ' libgcc-{}-dev:{}'.format(distro_gcc, distro_arch))
        d.appendVar('SBUILD_CHROOT_PREINSTALL_COMMON',
                    ' libstdc++-{}-dev:{}'.format(distro_gcc, distro_arch))

    if bb.utils.to_boolean(d.getVar('ISAR_ENABLE_COMPAT_ARCH')):
        compat_arch = d.getVar('COMPAT_DISTRO_ARCH')
        d.appendVar('SBUILD_CHROOT_COMPAT_PREINSTALL',
                    ' libc6-dev:{}'.format(compat_arch))
        d.appendVar('SBUILD_CHROOT_COMPAT_PREINSTALL',
                    ' crossbuild-essential-{}'.format(compat_arch))
        if d.getVar('DISTRO_GCC'):
            d.appendVar('SBUILD_CHROOT_COMPAT_PREINSTALL',
                        ' libgcc-{}-dev:{}'.format(distro_gcc, compat_arch))
            d.appendVar('SBUILD_CHROOT_COMPAT_PREINSTALL',
                        ' libstdc++-{}-dev:{}'.format(distro_gcc, compat_arch))
}

SBUILD_CHROOT_PREINSTALL_COMMON = " \
    ${SBUILD_CHROOT_COMPAT_PREINSTALL} \
    ${SBUILD_CHROOT_PREINSTALL_EXTRA} \
    libc6-dev:${DISTRO_ARCH} \
    fakeroot \
    build-essential \
    debhelper \
    ${@ 'ccache' if bb.utils.to_boolean(d.getVar('USE_CCACHE')) else ''} \
    devscripts \
    equivs \
"

SBUILD_CHROOT_DIR = "${WORKDIR}/rootfs"
ROOTFSDIR = "${SBUILD_CHROOT_DIR}"
ROOTFS_PACKAGES = "${SBUILD_CHROOT_PREINSTALL}"

ROOTFS_POSTPROCESS_COMMAND:remove = "rootfs_cleanup_isar_apt"

# Do not cleanup base-apt
ROOTFS_POSTPROCESS_COMMAND:remove = "rootfs_cleanup_base_apt"

DEPLOY_SCHROOT = "${@d.getVar('SCHROOT_' + d.getVar('SBUILD_VARIANT').upper() + '_DIR')}${SBUILD_SCHROOT_SUFFIX}"

do_sbuildchroot_deploy[dirs] = "${DEPLOY_DIR}/schroot-${SBUILD_VARIANT}"
do_sbuildchroot_deploy() {
    ln -Tfsr "${ROOTFSDIR}" "${DEPLOY_SCHROOT}"
}
addtask sbuildchroot_deploy before do_build after do_rootfs
