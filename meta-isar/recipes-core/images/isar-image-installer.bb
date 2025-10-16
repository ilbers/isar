# This software is a part of ISAR.
# Copyright (C) Siemens AG, 2024
#
# SPDX-License-Identifier: MIT

inherit image
inherit installer-add-rootfs
DESCRIPTION = "Example of a ISAR based Installer Image"

# Use variable to switch easily to another wks
INSTALLER_WKS_FILE ??= "installer-efi.wks.in"
WKS_FILE = "${INSTALLER_WKS_FILE}"

ADDITIONAL_KERNEL_CMDLINE ??= ""

OVERRIDES .= "${@':unattended-installer' if bb.utils.to_boolean(d.getVar('INSTALLER_UNATTENDED')) else ''}"
ADDITIONAL_KERNEL_CMDLINE:append:unattended-installer = " \
    installer.unattended \
    installer.image.uri=/install/${IMAGE_DATA_FILE}.${IMAGE_DATA_POSTFIX} \
    installer.target.dev=${INSTALLER_TARGET_DEVICE} \
    installer.target.overwrite=${INSTALLER_TARGET_OVERWRITE} \
    "

IMAGER_INSTALL:wic:append = " ${SYSTEMD_BOOTLOADER_INSTALL}"

IMAGE_INSTALL += "target-bootstrapper-service"

IMAGE_INSTALL:remove = "expand-on-first-boot"

IMAGE_PREINSTALL:append = "${@ bb.utils.contains('MACHINE_FEATURES', 'raid', ' mdadm', '', d) }"
