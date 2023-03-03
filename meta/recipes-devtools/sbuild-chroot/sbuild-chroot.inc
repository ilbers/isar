# Common part for build chroot filesystem.
#
# This software is a part of ISAR.
# Copyright (C) 2015-2021 ilbers GmbH

LICENSE = "gpl-2.0"
LIC_FILES_CHKSUM = "file://${LAYERDIR_core}/licenses/COPYING.GPLv2;md5=751419260aa954499f7abaabaa882bbe"

PV = "1.0"

inherit rootfs
inherit compat

python() {
    distro_gcc = d.getVar('DISTRO_GCC')
    distro_arch = d.getVar('DISTRO_ARCH')

    if d.getVar('DISTRO_GCC'):
        d.appendVar('SBUILD_CHROOT_PREINSTALL_COMMON',
                    ' libgcc-{}-dev:{}'.format(distro_gcc, distro_arch))
        d.appendVar('SBUILD_CHROOT_PREINSTALL_COMMON',
                    ' libstdc++-{}-dev:{}'.format(distro_gcc, distro_arch))

    if d.getVar('ISAR_ENABLE_COMPAT_ARCH') == '1':
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
    libc6-dev:${DISTRO_ARCH} \
    fakeroot \
    build-essential \
    debhelper \
    ${@ 'ccache' if d.getVar('USE_CCACHE') == '1' else ''} \
    devscripts \
    equivs \
"

SBUILD_CHROOT_DIR = "${WORKDIR}/rootfs"
ROOTFSDIR = "${SBUILD_CHROOT_DIR}"
ROOTFS_PACKAGES = "${SBUILD_CHROOT_PREINSTALL}"

# We don't need /etc/apt/sources.list.d/isar-apt.list' while it's handled by sbuild
ROOTFS_CONFIGURE_COMMAND:remove = "rootfs_configure_isar_apt"

DEPLOY_SCHROOT = "${@d.getVar('SCHROOT_' + d.getVar('SBUILD_VARIANT').upper() + '_DIR')}"

do_sbuildchroot_deploy[dirs] = "${DEPLOY_DIR}/schroot-${SBUILD_VARIANT}"
do_sbuildchroot_deploy() {
    ln -Tfsr "${ROOTFSDIR}" "${DEPLOY_SCHROOT}"
}
addtask sbuildchroot_deploy before do_build after do_rootfs
