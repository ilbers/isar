# This software is a part of ISAR.
# Copyright (c) Siemens, 2025
#
# SPDX-License-Identifier: MIT

inherit dpkg

FILESEXTRAPATHS:prepend := "${THISDIR}/files:"

S = "${WORKDIR}/git"

DEPENDS:append:bookworm = " python3-packageurl"
DEPENDS:append:noble = " python3-packageurl"

S = "${WORKDIR}/git"

MAINTAINER = "Christoph Steiger <christoph.steiger@siemens.com>"
DPKG_ARCH = "all"
DEBIAN_BUILD_DEPENDS = "dh-python, \
                        python3-all, \
                        python3-setuptools, \
                        pybuild-plugin-pyproject, \
                        python3-packageurl, \
                        python3-debian, \
                        python3-requests, \
                        python3-zstandard, \
                        "

DEBIAN_DEPENDS = "python3-apt, \${python3:Depends}, \${misc:Depends}"

DESCRIPTION = "debsbom generates SBOMs for Debian based distributions."

SRC_URI = "git://github.com/siemens/debsbom.git;protocol=https;branch=main; \
           file://rules \
           file://0001-Use-old-license-description-in-pyproject.toml.patch \
           "
SRCREV = "ba63720dfc0dc6dcb01994031e092aaebb62a399"

do_prepare_build[cleandirs] += "${S}/debian"
do_prepare_build() {
    deb_debianize
}
