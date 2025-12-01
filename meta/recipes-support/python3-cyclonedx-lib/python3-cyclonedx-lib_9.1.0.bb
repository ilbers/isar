# This software is a part of ISAR.
# Copyright (c) Siemens, 2025
#
# SPDX-License-Identifier: MIT

inherit dpkg

FILESEXTRAPATHS:prepend := "${THISDIR}/files:"

DEPENDS:append:bookworm = " python3-packageurl python3-py-serializable"
DEPENDS:append:noble = " python3-packageurl python3-py-serializable"

S = "${WORKDIR}/cyclonedx_python_lib-${PV}"

MAINTAINER = "Christoph Steiger <christoph.steiger@siemens.com>"
DPKG_ARCH = "all"
DEBIAN_BUILD_DEPENDS = "debhelper (>= 11~), \
                        dh-python, \
                        python3-all, \
                        python3-setuptools, \
                        pybuild-plugin-pyproject, \
                        python3-poetry, \
                        python3-py-serializable, \
                        python3-packageurl, \
                        python3-sortedcontainers, \
                        python3-ddt, \
                        python3-defusedxml, \
                        python3-license-expression, \
                        python3-jsonschema, \
                        python3-lxml, \
                        "

DEBIAN_DEPENDS = "\${python3:Depends}, \${misc:Depends}"

DESCRIPTION = "Library for serializing and deserializing Python Objects to and from JSON and XML."

SRC_URI = "\
    https://github.com/CycloneDX/cyclonedx-python-lib/releases/download/v9.1.0/cyclonedx_python_lib-9.1.0.tar.gz \
    file://rules \
    file://pybuild.testfiles \
    "
SRC_URI[sha256sum] = "86935f2c88a7b47a529b93c724dbd3e903bc573f6f8bd977628a7ca1b5dadea1"

do_prepare_build[cleandirs] += "${S}/debian"
do_prepare_build() {
    cp "${WORKDIR}"/pybuild.testfiles "${S}"/debian
    deb_debianize
}
