# This software is a part of ISAR.
# Copyright (c) Siemens, 2025
#
# SPDX-License-Identifier: MIT

inherit dpkg

FILESEXTRAPATHS:prepend := "${THISDIR}/files:"

S = "${WORKDIR}/beartype-${PV}"

MAINTAINER = "Christoph Steiger <christoph.steiger@siemens.com>"
DPKG_ARCH = "all"
DEBIAN_BUILD_DEPENDS = "debhelper (>= 11~), dh-python, python3-all, python3-setuptools, pybuild-plugin-pyproject, python3-hatchling"
DEBIAN_DEPENDS = "\${python3:Depends}, \${misc:Depends}"
# this is 01/01/1980, any earlier and zip in the wheel building process will not accept it
DEBIAN_CHANGELOG_TIMESTAMP = "315532800"
DESCRIPTION = "Unbearably fast near-real-time hybrid runtime-static type-checking in pure Python."

SRC_URI = "\
    https://github.com/beartype/beartype/archive/refs/tags/v0.19.0.tar.gz \
    file://rules \
    "
SRC_URI[sha256sum] = "e7ad00eebf527d60f30e0b391209b561dabd2074b608c50e26c94c2d8250a6cd"

do_prepare_build[cleandirs] += "${S}/debian"
do_prepare_build() {
    deb_debianize
}
