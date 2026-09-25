# This software is a part of Isar.
# Copyright (C) 2026 Siemens AG

inherit dpkg-raw

MAINTAINER = "isar-users <isar-users@googlegroups.com>"
DESCRIPTION = "Minimal ldd replacement for dracut cross builds"

SRC_URI = "file://${BPN}"

DEBIAN_DEPENDS .= ",python3, binutils"

do_install[cleandirs] += "${D}/usr/libexec"
do_install() {
    install -v -m 755 "${WORKDIR}/${BPN}" "${D}/usr/libexec/${BPN}"
}
