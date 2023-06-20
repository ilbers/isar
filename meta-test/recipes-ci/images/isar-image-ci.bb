# CI root filesystem for target installation
#
# This software is a part of ISAR.
# Copyright (C) 2023 ilbers GmbH

require recipes-core/images/isar-image-base.bb

FILESEXTRAPATHS:append = ":${LAYERDIR_isar}/recipes-core/images:"

# Avoid ISAR_RELEASE_CMD warning in image.bbclass
ISAR_RELEASE_CMD = "git -C ${LAYERDIR_test} describe --tags --dirty --match 'v[0-9].[0-9]*'"

# Setup SSH server on board
IMAGE_INSTALL += "isar-ci-ssh-setup"

# qemuamd64-bookworm
WKS_FILE:qemuamd64:debian-bookworm ?= "multipart-efi.wks"

# qemuamd64-focal
WKS_FILE:qemuamd64:ubuntu-focal ?= "sdimage-efi-sd"
IMAGER_INSTALL:remove:qemuamd64:ubuntu-focal ?= "${GRUB_BOOTLOADER_INSTALL}"
IMAGER_INSTALL:append:qemuamd64:ubuntu-focal ?= " ${SYSTEMD_BOOTLOADER_INSTALL}"

# qemuamd64-jammy
WKS_FILE:qemuamd64:ubuntu-jammy ?= "sdimage-efi-sd"
IMAGER_INSTALL:remove:qemuamd64:ubuntu-jammy ?= "${GRUB_BOOTLOADER_INSTALL}"
IMAGER_INSTALL:append:qemuamd64:ubuntu-jammy ?= " ${SYSTEMD_BOOTLOADER_INSTALL}"
