# This software is a part of ISAR.
# Copyright (c) Siemens, 2025
#
# SPDX-License-Identifier: MIT

inherit dpkg

FILESEXTRAPATHS:prepend := "${THISDIR}/files:"

S = "${WORKDIR}/tools-python-${PV}"

DEPENDS:append:bookworm = " python3-beartype"

MAINTAINER = "Christoph Steiger <christoph.steiger@siemens.com>"
DPKG_ARCH = "all"
DEBIAN_BUILD_DEPENDS = "dh-python, \
                        python3-all, \
                        python3-setuptools, \
                        python3-beartype, \
                        python3-semantic-version, \
                        python3-license-expression, \
                        python3-pytest <!nocheck>, \
                        python3-rdflib, \
                        python3-uritools, \
                        python3-ply, \
                        python3-click, \
                        python3-xmltodict, \
                        python3-yaml, \
                        "

DEBIAN_DEPENDS = "\${python3:Depends}, \${misc:Depends}"
DEB_BUILD_PROFILES += "nocheck"
DEB_BUILD_OPTIONS += "nocheck"

DESCRIPTION = "SPDX parser and tools."

SRC_URI = "\
    https://github.com/spdx/tools-python/archive/refs/tags/v0.8.3.tar.gz \
    file://rules \
    "
SRC_URI[sha256sum] = "17cb0140adbaefb58819c9d5d56060dc6a70c673a854fa9bd882ecfa4e062a7f"

do_prepare_build[cleandirs] += "${S}/debian"
do_prepare_build() {
    deb_debianize
}
