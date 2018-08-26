# Common part for build chroot filesystem.
#
# This software is a part of ISAR.
# Copyright (C) 2015-2018 ilbers GmbH

LICENSE = "gpl-2.0"
LIC_FILES_CHKSUM = "file://${LAYERDIR_isar}/licenses/COPYING.GPLv2;md5=751419260aa954499f7abaabaa882bbe"

FILESPATH_prepend := "${THISDIR}/files:"
SRC_URI = "file://configscript.sh \
           file://build.sh \
           file://common.sh \
           file://deps.sh"
PV = "1.0"

inherit isar-bootstrap-helper

WORKDIR = "${TMPDIR}/work/${DISTRO}-${DISTRO_ARCH}/${PN}"
BUILDCHROOT_DIR = "${WORKDIR}/rootfs"

do_build[stamp-extra-info] = "${DISTRO}-${DISTRO_ARCH}"
do_build[root_cleandirs] = "${BUILDCHROOT_DIR} \
                            ${BUILDCHROOT_DIR}/isar-apt \
                            ${BUILDCHROOT_DIR}/downloads \
                            ${BUILDCHROOT_DIR}/home/builder"

do_build() {
    setup_root_file_system ${PARAMS} ${BUILDCHROOT_DIR} ${BUILDCHROOT_PREINSTALL}

    # Install package builder script
    sudo chmod -R a+rw "${BUILDCHROOT_DIR}/home/builder"
    sudo install -m 755 -d ${BUILDCHROOT_DIR}/isar
    sudo install -m 755 ${WORKDIR}/build.sh ${BUILDCHROOT_DIR}/isar/
    sudo install -m 755 ${WORKDIR}/common.sh ${BUILDCHROOT_DIR}/isar/
    sudo install -m 755 ${WORKDIR}/deps.sh ${BUILDCHROOT_DIR}/isar/

    # Configure root filesystem
    sudo install -m 755 ${WORKDIR}/configscript.sh ${BUILDCHROOT_DIR}
    sudo chroot ${BUILDCHROOT_DIR} /configscript.sh

    sudo mount --bind ${DL_DIR} ${BUILDCHROOT_DIR}/downloads
}
