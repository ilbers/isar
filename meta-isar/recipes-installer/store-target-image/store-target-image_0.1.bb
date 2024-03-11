# This software is a part of ISAR.
# Copyright (C) Siemens AG, 2024
#
# SPDX-License-Identifier: MIT

DESCRIPTION = "Add a given target image to rootfs"

inherit dpkg-raw

INSTALLER_TARGET_IMAGE ??= "isar-image-base"
IMG_DATA_FILE ??= "${INSTALLER_TARGET_IMAGE}-${DISTRO}-${MACHINE}"
IMG_DATA_POSTFIX ??= "wic.zst"
IMG_DATA_POSTFIX:buster ??= "wic.xz"
IMG_DATA_POSTFIX:bullseye ??= "wic.xz"
do_install[mcdepends] = "${@ 'mc:isar-installer:installer-target:' + d.getVar('INSTALLER_TARGET_IMAGE') + ':do_image_wic' if d.getVar('INSTALLER_TARGET_IMAGE') else ''}"
do_install[cleandirs] = "${D}/install/"
do_install() {
  if [ -f ${DEPLOY_DIR_IMAGE}/${IMG_DATA_FILE}.${IMG_DATA_POSTFIX} ]; then
    install -m 0600  ${DEPLOY_DIR_IMAGE}/${IMG_DATA_FILE}.${IMG_DATA_POSTFIX} ${D}/install/
    install -m 0600  ${DEPLOY_DIR_IMAGE}/${IMG_DATA_FILE}.wic.bmap ${D}/install/
  else
    # mcopy cannot handle .keep or empty directory , therefore use visible file
    touch ${D}/install/keep
  fi
}
