# This software is a part of ISAR.
# Copyright (c) Siemens, 2025
#
# SPDX-License-Identifier: MIT

inherit dpkg

FILESEXTRAPATHS:prepend := "${THISDIR}/files:"

S = "${WORKDIR}/git"

DEPENDS = "python3-spdx-tools"
DEPENDS:append:bookworm = " python3-packageurl python3-cyclonedx-lib"
DEPENDS:append:noble = " python3-packageurl python3-cyclonedx-lib"

S = "${WORKDIR}/git"

MAINTAINER = "Christoph Steiger <christoph.steiger@siemens.com>"
DPKG_ARCH = "all"
DEBIAN_BUILD_DEPENDS = "dh-python, \
                        python3-all, \
                        python3-setuptools, \
                        pybuild-plugin-pyproject, \
                        python3-packageurl, \
                        python3-cyclonedx-lib, \
                        python3-spdx-tools, \
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
SRCREV = "a600f60966d08803eb17bfb81eb8828921497453"

do_prepare_build[cleandirs] += "${S}/debian"
do_prepare_build() {
    deb_debianize
}
