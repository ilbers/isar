# This software is a part of ISAR.
# Copyright (c) Siemens, 2025
#
# SPDX-License-Identifier: MIT

inherit dpkg

FILESEXTRAPATHS:prepend := "${THISDIR}/files:"

S = "${WORKDIR}/packageurl_python-${PV}"

MAINTAINER = "Christoph Steiger <christoph.steiger@siemens.com>"
DPKG_ARCH = "all"
DEBIAN_BUILD_DEPENDS = "debhelper (>= 11~), \
                        dh-python, \
                        python3-all, \
                        python3-setuptools, \
                        "

DEBIAN_DEPENDS = "\${python3:Depends}, \${misc:Depends}"

DESCRIPTION = "A purl aka. Package URL parser and builder"

SRC_URI = "\
    https://github.com/package-url/packageurl-python/releases/download/v0.16.0/packageurl_python-0.16.0.tar.gz \
    file://rules \
    "
SRC_URI[sha256sum] = "69e3bf8a3932fe9c2400f56aaeb9f86911ecee2f9398dbe1b58ec34340be365d"

do_prepare_build[cleandirs] += "${S}/debian"
do_prepare_build() {
    deb_debianize
}
