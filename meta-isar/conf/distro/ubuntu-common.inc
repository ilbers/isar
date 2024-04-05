#
# Copyright (c) Siemens AG, 2018-2023
#
# SPDX-License-Identifier: MIT

require conf/distro/debian-common.conf

BASE_DISTRO = "ubuntu"

HOST_BASE_DISTRO = "${BASE_DISTRO}"

DISTRO_APT_SOURCES:arm64 ?= "conf/distro/${BASE_DISTRO}-${BASE_DISTRO_CODENAME}-ports.list"
HOST_DISTRO_APT_SOURCES:arm64 ?= "conf/distro/${HOST_DISTRO}.list conf/distro/${HOST_DISTRO}-ports.list"

BOOTSTRAP_KEY = "file://${LAYERDIR_isar}/conf/distro/ubuntu.public.key;sha256sum=36a38199a4bf4eae1e7f574891f7dfcb79b91b87a33a499383265e1224b5e989"
DISTRO_BOOTSTRAP_KEYS += "${BOOTSTRAP_KEY}"
HOST_DISTRO_BOOTSTRAP_KEYS += "${BOOTSTRAP_KEY}"

# kernel package name is linux-image-generic in Ubuntu
KERNEL_NAME = "generic"

# that is what debootstrap_1.0.118ubuntu1 does anyways
DISTRO_DEBOOTSTRAP_SCRIPT = "/usr/share/debootstrap/scripts/gutsy"

DISTRO_CONFIG_SCRIPT ?= "debian-configscript.sh"

DISTRO_KERNELS ?= " \
    aws azure azure-edge gcp generic gke kvm lowlatency oem virtual \
    snapdragon generic-lpae"

IMAGE_PREINSTALL += "init"
IMAGE_PREINSTALL += "initramfs-tools"

IMAGER_INSTALL:wic += "python3-distutils"

SYSTEMD_BOOTLOADER_INSTALL:focal = "systemd:${DISTRO_ARCH}"
SYSTEMD_BOOTLOADER_INSTALL:jammy = "systemd:${DISTRO_ARCH}"
