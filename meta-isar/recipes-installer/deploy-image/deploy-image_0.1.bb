# This software is a part of ISAR.
# Copyright (C) Siemens AG, 2024
#
# SPDX-License-Identifier: MIT

DESCRIPTION = "add target image to rootfs"


inherit dpkg-raw

SRC_URI = "file://deploy-image-wic.sh \
           file://install.override.conf \
          "
DEBIAN_DEPENDS = "bmap-tools, pv, dialog, util-linux, parted, fdisk, gdisk, pigz, xz-utils, pbzip2, zstd"
do_install[cleandirs] = "${D}/usr/bin/ \
                         ${D}/usr/lib/systemd/system/getty@tty1.service.d/ \
                         ${D}/usr/lib/systemd/system/serial-getty@ttyS0.service.d/"
do_install() {
  install -m 0755  ${WORKDIR}/deploy-image-wic.sh ${D}/usr/bin/deploy-image-wic.sh
  install -m 0600 ${WORKDIR}/install.override.conf ${D}/usr/lib/systemd/system/getty@tty1.service.d/override.conf
  install -m 0600 ${WORKDIR}/install.override.conf ${D}/usr/lib/systemd/system/serial-getty@ttyS0.service.d/override.conf
}
