# Sample application
#
# This software is a part of ISAR.
# Copyright (C) 2026 Siemens AG

inherit dpkg

DESCRIPTION = "Hello world example for Rust"
MAINTAINER = "isar-users <isar-users@googlegroups.com>"

SRC_URI = "file://${BPN} \
           file://rules"

DEBIAN_BUILD_DEPENDS += "dh-cargo"

S = "${WORKDIR}/${BPN}"

do_prepare_build() {
    deb_debianize
    install  -m 644 ${WORKDIR}/rules ${S}/debian/rules
}
