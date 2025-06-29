# This software is a part of ISAR.
# Copyright (C) Siemens AG, 2024
#
# SPDX-License-Identifier: MIT

DESCRIPTION = "Install image to device"

inherit dpkg-raw

SRC_URI = "file://usr/bin/deploy-image-wic.sh \
           file://usr/lib/deploy-image-wic/handle-config.sh \
          "

DEPENDS:append:bookworm = " bmap-tools"
DEPENDS:append = " systemd-tmpfs-tmp"
DEBIAN_DEPENDS = "bmap-tools, pv, dialog, util-linux, parted, fdisk, gdisk, pigz, systemd-tmpfs-tmp, xz-utils, pbzip2, zstd"
do_install[cleandirs] = "${D}/usr/bin/ \
                         ${D}/usr/lib/deploy-image-wic \
                        "
do_install() {
    install -m 0755  ${WORKDIR}/usr/bin/deploy-image-wic.sh ${D}/usr/bin/deploy-image-wic.sh
    install -m 0755  ${WORKDIR}/usr/lib/deploy-image-wic/handle-config.sh ${D}/usr/lib/deploy-image-wic/handle-config.sh
}
