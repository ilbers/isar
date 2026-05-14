# This software is a part of Isar.
# Copyright (C) Siemens AG, 2024-2026
#
# SPDX-License-Identifier: MIT

DESCRIPTION = "Install image to device"
MAINTAINER = "isar-users <isar-users@googlegroups.com>"

inherit dpkg-raw

SRC_URI = "file://usr/bin/deploy-image-wic.sh \
           file://usr/bin/sys_api.sh \
           file://usr/bin/installer_ui.sh \
           file://usr/lib/deploy-image-wic/handle-config.sh \
          "

DEPENDS:append:bookworm = " bmap-tools"
DEBIAN_DEPENDS = "bmap-tools, pv, dialog, util-linux, parted, fdisk, gdisk, pigz, procps, xz-utils, pbzip2, zstd"
do_install[cleandirs] = "${D}/usr/bin/ \
                         ${D}/usr/lib/deploy-image-wic \
                        "
do_install() {
    install -m 0755  ${WORKDIR}/usr/bin/deploy-image-wic.sh ${D}/usr/bin/deploy-image-wic.sh
    install -m 0755  ${WORKDIR}/usr/bin/sys_api.sh ${D}/usr/bin/sys_api.sh
    install -m 0755  ${WORKDIR}/usr/bin/installer_ui.sh ${D}/usr/bin/installer_ui.sh
    install -m 0755  ${WORKDIR}/usr/lib/deploy-image-wic/handle-config.sh ${D}/usr/lib/deploy-image-wic/handle-config.sh
}
