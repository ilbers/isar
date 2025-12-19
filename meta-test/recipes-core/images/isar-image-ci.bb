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
IMAGE_INSTALL += "sshd-regen-keys"

# qemuamd64-bookworm
WKS_FILE:qemuamd64:debian-bookworm ?= "multipart-efi.wks"

# qemuamd64-bullseye
IMAGE_FSTYPES:append:qemuamd64:debian-bullseye ?= " cpio.zst tar.zst"
WKS_FILE:qemuamd64:debian-bullseye ?= "sdimage-efi-btrfs"
IMAGE_INSTALL:append:qemuamd64:debian-bullseye = " expand-on-first-boot"
IMAGER_INSTALL:remove:qemuamd64:debian-bullseye ?= "${GRUB_BOOTLOADER_INSTALL}"
IMAGER_INSTALL:append:qemuamd64:debian-bullseye ?= " ${SYSTEMD_BOOTLOADER_INSTALL} btrfs-progs"
IMAGE_PREINSTALL:append:qemuamd64:debian-bullseye ?= " btrfs-progs"
# Explicitly remove from wic since it is set in qemuamd64.conf:
IMAGER_INSTALL:wic:remove:qemuamd64:debian-bullseye ?= "${GRUB_BOOTLOADER_INSTALL}"

# qemuamd64-buster
IMAGE_FSTYPES:qemuamd64:debian-buster ?= "wic ext4"
WKS_FILE:qemuamd64:debian-buster ?= "efi-plus-pcbios"
IMAGER_INSTALL:append:qemuamd64:debian-buster ?= " ${SYSLINUX_BOOTLOADER_INSTALL}"

# qemuamd64-focal
WKS_FILE:qemuamd64:ubuntu-focal ?= "sdimage-efi-sd"
IMAGER_INSTALL:remove:qemuamd64:ubuntu-focal ?= "${GRUB_BOOTLOADER_INSTALL}"
IMAGER_INSTALL:append:qemuamd64:ubuntu-focal ?= " ${SYSTEMD_BOOTLOADER_INSTALL}"

# qemuamd64-jammy
WKS_FILE:qemuamd64:ubuntu-jammy ?= "sdimage-efi-sd"
IMAGER_INSTALL:remove:qemuamd64:ubuntu-jammy ?= "${GRUB_BOOTLOADER_INSTALL}"
IMAGER_INSTALL:append:qemuamd64:ubuntu-jammy ?= " ${SYSTEMD_BOOTLOADER_INSTALL}"

# qemuarm-bookworm
IMAGE_FSTYPES:append:qemuarm:debian-bookworm ?= " wic"
WKS_FILE:qemuarm:debian-bookworm ?= "sdimage-efi-sd"
IMAGE_INSTALL:append:qemuarm:debian-bookworm = " expand-on-first-boot"
IMAGER_INSTALL:append:qemuarm:debian-bookworm ?= " ${SYSTEMD_BOOTLOADER_INSTALL}"

# qemuarm64-bookworm
IMAGE_FSTYPES:append:qemuarm64:debian-bookworm ?= " wic.xz"
IMAGER_INSTALL:append:qemuarm64:debian-bookworm ?= " ${GRUB_BOOTLOADER_INSTALL}"
