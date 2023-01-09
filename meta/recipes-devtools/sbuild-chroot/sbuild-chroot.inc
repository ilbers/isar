# Common part for build chroot filesystem.
#
# This software is a part of ISAR.
# Copyright (C) 2015-2021 ilbers GmbH

LICENSE = "gpl-2.0"
LIC_FILES_CHKSUM = "file://${LAYERDIR_core}/licenses/COPYING.GPLv2;md5=751419260aa954499f7abaabaa882bbe"

PV = "1.0"

inherit rootfs

SBUILD_CHROOT_PREINSTALL_COMMON = " \
    fakeroot \
    build-essential \
    debhelper \
    ${@ 'ccache' if d.getVar('USE_CCACHE') == '1' else ''} \
    devscripts \
    equivs \
"

SBUILD_CHROOT_PREINSTALL ?= " \
    ${SBUILD_CHROOT_PREINSTALL_COMMON} \
"

SBUILD_CHROOT_DIR = "${WORKDIR}/rootfs"
ROOTFSDIR = "${SBUILD_CHROOT_DIR}"
ROOTFS_PACKAGES = "${SBUILD_CHROOT_PREINSTALL}"

# We don't need /etc/apt/sources.list.d/isar-apt.list' while it's handled by sbuild
ROOTFS_CONFIGURE_COMMAND_remove = "rootfs_configure_isar_apt"

DEPLOY_SCHROOT = "${@d.getVar('SCHROOT_' + d.getVar('SBUILD_VARIANT').upper() + '_DIR')}"

do_sbuildchroot_deploy[dirs] = "${DEPLOY_DIR}/schroot-${SBUILD_VARIANT}"
do_sbuildchroot_deploy() {
    ln -Tfsr "${ROOTFSDIR}" "${DEPLOY_SCHROOT}"
}
addtask sbuildchroot_deploy before do_build after do_rootfs
