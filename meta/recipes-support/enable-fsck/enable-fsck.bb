# Resize last partition to full medium size on fist boot
#
# This software is a part of ISAR.
# Copyright (c) Siemens AG, 2018
#
# SPDX-License-Identifier: MIT

inherit dpkg-raw

DESCRIPTION = "This service enables fsck on first boot"

DEBIAN_DEPENDS = "systemd, sed, mount, initramfs-tools"

SRC_URI = " \
    file://enable-fsck.service \
    file://enable-fsck.sh \
    file://postinst"

do_install() {
    install -d -m 755 ${D}/lib/systemd/system
    install -m 644 ${WORKDIR}/enable-fsck.service ${D}/lib/systemd/system/

    install -d -m 755 ${D}/usr/share/enable-fsck
    install -m 755 ${WORKDIR}/enable-fsck.sh ${D}/usr/share/enable-fsck/
}
