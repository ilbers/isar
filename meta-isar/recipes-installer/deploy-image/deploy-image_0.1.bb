# This software is a part of ISAR.
# Copyright (C) Siemens AG, 2024
#
# SPDX-License-Identifier: MIT

DESCRIPTION = "Install image to device"

inherit dpkg-raw

SRC_URI = "file://deploy-image-wic.sh \
          "
DEBIAN_DEPENDS = "bmap-tools, pv, dialog, util-linux, parted, fdisk, gdisk, pigz, xz-utils, pbzip2, zstd"
do_install[cleandirs] = "${D}/usr/bin/ \
                        "
do_install() {
  install -m 0755  ${WORKDIR}/deploy-image-wic.sh ${D}/usr/bin/deploy-image-wic.sh
}
