# Common part for build chroot filesystem.
#
# This software is a part of ISAR.
# Copyright (C) 2015-2018 ilbers GmbH

LICENSE = "gpl-2.0"
LIC_FILES_CHKSUM = "file://${LAYERDIR_core}/licenses/COPYING.GPLv2;md5=751419260aa954499f7abaabaa882bbe"

FILESPATH_prepend := "${THISDIR}/files:"
SRC_URI = "file://configscript.sh \
           file://build.sh \
           file://common.sh \
           file://deps.sh"
PV = "1.0"

inherit rootfs

BUILDCHROOT_DIR = "${WORKDIR}/rootfs"
ROOTFSDIR = "${BUILDCHROOT_DIR}"
ROOTFS_PACKAGES = "${BUILDCHROOT_PREINSTALL}"
ROOTFS_CLEAN_FILES = ""

rootfs_do_mounts_append() {
    sudo -s <<'EOSUDO'
    mkdir -p '${BUILDCHROOT_DIR}/downloads'
    mountpoint -q '${BUILDCHROOT_DIR}/downloads' || \
        mount --bind '${DL_DIR}' '${BUILDCHROOT_DIR}/downloads'
EOSUDO
}

ROOTFS_POSTPROCESS_COMMAND =+ "buildchroot_install_files"
buildchroot_install_files() {
    sudo mkdir -p "${BUILDCHROOT_DIR}/home/builder"
    sudo mkdir -p "${BUILDCHROOT_DIR}/isar-apt"
    # Install package builder script
    sudo chmod -R a+rw "${BUILDCHROOT_DIR}/home/builder"
    sudo install -m 755 -d ${BUILDCHROOT_DIR}/isar
    sudo install -m 755 ${WORKDIR}/build.sh ${BUILDCHROOT_DIR}/isar/
    sudo install -m 755 ${WORKDIR}/common.sh ${BUILDCHROOT_DIR}/isar/
    sudo install -m 755 ${WORKDIR}/deps.sh ${BUILDCHROOT_DIR}/isar/

    # Configure root filesystem
    sudo install -m 755 ${WORKDIR}/configscript.sh ${BUILDCHROOT_DIR}
    USER_ID=$(id -u)
    GROUP_ID=$(id -g)
    sudo chroot ${BUILDCHROOT_DIR} /configscript.sh $USER_ID $GROUP_ID

}
