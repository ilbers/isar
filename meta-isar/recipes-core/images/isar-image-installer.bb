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
IMAGER_INSTALL:wic:append = " ${SYSTEMD_BOOTLOADER_INSTALL}"

IMAGE_INSTALL += "deploy-image-service"

IMAGE_INSTALL:remove = "expand-on-first-boot"
