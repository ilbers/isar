# This software is a part of ISAR.
# Copyright (c) Siemens AG, 2025
#
# SPDX-License-Identifier: MIT

inherit dpkg-raw

MAINTAINER ?= "isar-users <isar-users@googlegroups.com>"
DESCRIPTION = "Definitions to generate Discoverable Disk Image"

DEBIAN_DEPENDS = "systemd, systemd-repart, cryptsetup, openssl, erofs-utils"

SRC_URI = "file://definitions"

do_install[cleandirs] = "${D}/usr/share/${BPN}"
do_install() {
    cp -a ${WORKDIR}/definitions/* ${D}/usr/share/${BPN}/
}
