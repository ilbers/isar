# This software is a part of ISAR.
# Copyright (C) 2025 Siemens

DISTRO_ARCH ?= "arm64"
KERNEL_NAME ?= "arm64"

IMAGE_FSTYPES ?= "wic"
WKS_FILE ?= "rpi-arm64-v8-efi.wks"

IMAGER_BUILD_DEPS = "bootconfig-rpi-efi"
IMAGER_INSTALL:wic += "${IMAGER_BUILD_DEPS}"

IMAGE_EFI_BOOT_FILES = " \
    /usr/lib/bootconfig-rpi-efi/config.txt;config.txt \
    /usr/lib/u-boot/rpi_arm64/u-boot.bin;u-boot.bin \
    /usr/lib/rpi-firmware/fixup4.dat;fixup4.dat \
    /usr/lib/rpi-firmware/start4.elf;start4.elf \
    /usr/lib/rpi-firmware/overlays/*;overlays/ \
    ${IMAGE_ROOTFS}/usr/lib/linux-image-*/broadcom/bcm2711-rpi-4*.dtb \
"

IMAGE_PREINSTALL:append = " firmware-brcm80211"
