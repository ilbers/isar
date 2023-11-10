# This software is a part of ISAR.
# Copyright (C) 2015-2016 ilbers GmbH
#
# Based on SD class from meta-raspberrypi

IMAGE_TYPEDEP:rpi_sdimg = "wic"

WKS_FILE ?= "rpi-sdimg"

IMAGER_INSTALL:wic += "parted \
                       dosfstools \
                       mtools \
                       e2fsprogs \
                       python3-distutils \
                       bmap-tools"

IMAGE_BOOT_FILES ?= "${IMAGE_ROOTFS}/boot/*.*;./ \
                     ${IMAGE_ROOTFS}/boot/overlays/*;overlays/"

IMAGE_INSTALL += "bootconfig-${MACHINE}"

python do_wic_image:prepend() {
    bb.warn("rpi-sdimg image type is deprecated, please change to wic.")
}
