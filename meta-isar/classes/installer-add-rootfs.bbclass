# Copy the target image to the installer image
#
# This software is a part of ISAR.
# Copyright (C) Siemens AG, 2024
#
# SPDX-License-Identifier: MIT

inherit rootfs-add-files

INSTALLER_MC ??= "isar-installer"
INSTALLER_TARGET_IMAGE ??= "isar-image-base"
INSTALLER_TARGET_MC ??= "installer-target"
INSTALLER_TARGET_DISTRO ??= "${DISTRO}"
INSTALLER_TARGET_MACHINE ??= "${MACHINE}"

IMAGE_DATA_FILE ??= "${INSTALLER_TARGET_IMAGE}-${INSTALLER_TARGET_DISTRO}-${INSTALLER_TARGET_MACHINE}"
IMAGE_DATA_POSTFIX ??= "wic.zst"
IMAGE_DATA_POSTFIX:buster ??= "wic.xz"
IMAGE_DATA_POSTFIX:bullseye ??= "wic.xz"

ROOTFS_ADDITIONAL_FILES ??= "installer-target installer-target-bmap"

def get_installer_source(d, suffix):
    installer_target_image = d.getVar('INSTALLER_TARGET_IMAGE') or ""
    if not installer_target_image:
        return ""
    deploy_dir = d.getVar('DEPLOY_DIR_IMAGE')
    image_data = d.getVar('IMAGE_DATA_FILE')
    return f"{deploy_dir}/{image_data}.{suffix}"

def get_installer_destination(d, suffix):
    installer_target_image = d.getVar('INSTALLER_TARGET_IMAGE') or ""
    if not installer_target_image:
        return "/install/keep"
    image_data = d.getVar('IMAGE_DATA_FILE')
    return f"/install/{image_data}.{suffix}"

def get_mc_depends(d, task):
    installer_target_image = d.getVar('INSTALLER_TARGET_IMAGE') or ""
    if not installer_target_image:
        return ""
    installer_mc = d.getVar('INSTALLER_MC') or ""
    installer_target_mc = d.getVar('INSTALLER_TARGET_MC') or ""
    return f"mc:{installer_mc}:{installer_target_mc}:{installer_target_image}:{task}"

ROOTFS_ADDITIONAL_FILE_installer-target[source] = "${@ get_installer_source(d, d.getVar('IMAGE_DATA_POSTFIX'))}"
ROOTFS_ADDITIONAL_FILE_installer-target[destination] = "${@ get_installer_destination(d, d.getVar('IMAGE_DATA_POSTFIX'))}"
ROOTFS_ADDITIONAL_FILE_installer-target-bmap[source] = "${@ get_installer_source(d, "wic.bmap")}"
ROOTFS_ADDITIONAL_FILE_installer-target-bmap[destination] = "${@ get_installer_destination(d, "wic.bmap")}"

do_rootfs_install[mcdepends] += "${@ get_mc_depends(d, "do_image_wic")}"
