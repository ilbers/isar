# This software is a part of ISAR.
# Copyright (c) Siemens, 2025
#
# SPDX-License-Identifier: MIT

inherit dpkg

FILESEXTRAPATHS:prepend := "${THISDIR}/files:"

S = "${WORKDIR}/py_serializable-${PV}"

MAINTAINER = "Christoph Steiger <christoph.steiger@siemens.com>"
DPKG_ARCH = "all"
DEBIAN_BUILD_DEPENDS = " \
    dh-sequence-python3, \
    pybuild-plugin-pyproject, \
    python3-all, \
    python3-defusedxml, \
    python3-lxml, \
    python3-poetry-core, \
    python3-setuptools, \
    xmldiff, \
"

DEBIAN_DEPENDS = "\${python3:Depends}, \${misc:Depends}"

DESCRIPTION = "Library for serializing and deserializing Python Objects to and from JSON and XML."

SRC_URI = "\
    https://github.com/madpah/serializable/releases/download/v2.0.0/py_serializable-2.0.0.tar.gz \
    file://rules \
    "
SRC_URI[sha256sum] = "e9e6491dd7d29c31daf1050232b57f9657f9e8a43b867cca1ff204752cf420a5"

do_prepare_build[cleandirs] += "${S}/debian"
do_prepare_build() {
    deb_debianize
}
