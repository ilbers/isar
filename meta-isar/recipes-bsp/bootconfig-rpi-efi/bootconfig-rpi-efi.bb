# This software is a part of ISAR.
# Copyright (C) 2025 Siemens

inherit dpkg-raw

SRC_URI = "file://config.txt"

DESCRIPTION = "Raspberry Pi config to boot using U-Boot EFI"
MAINTAINER = "isar-users <isar-users@googlegroups.com>"

DPKG_ARCH = "arm64"
DEBIAN_DEPENDS = "firmware-rpi, u-boot-rpi"
RDEPENDS:${PN} += "firmware-rpi"

do_install[cleandirs] += "${D}/usr/lib/${BPN}"
do_install() {
    DST=${D}/usr/lib/${BPN}
    install -m 0644 ${WORKDIR}/config.txt $DST
}
