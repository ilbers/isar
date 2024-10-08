# This software is a part of ISAR.
# Copyright (C) Siemens AG, 2024
#
# SPDX-License-Identifier: MIT

DESCRIPTION = "systemd service to add target image to rootfs"


inherit dpkg-raw

SRC_URI = "file://install.override.conf \
          "
DEPENDS += " deploy-image"
DEBIAN_DEPENDS = "deploy-image"

do_install[cleandirs] = "${D}/usr/lib/systemd/system/getty@tty1.service.d/ \
                         ${D}/usr/lib/systemd/system/serial-getty@ttyS0.service.d/"
do_install() {
  install -m 0600 ${WORKDIR}/install.override.conf ${D}/usr/lib/systemd/system/getty@tty1.service.d/override.conf
  install -m 0600 ${WORKDIR}/install.override.conf ${D}/usr/lib/systemd/system/serial-getty@ttyS0.service.d/override.conf
}
