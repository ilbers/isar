# libubootenv
#
# This software is a part of ISAR.
# Copyright (c) Siemens AG, 2020
#
# SPDX-License-Identifier: MIT

DESCRIPTION = "Standalone library & tools for accessing the U-Boot environment"
HOMEPAGE= "https://github.com/sbabic/libubootenv"
LICENSE = "GPL-2.0"
LIC_FILES_CHKSUM = "file://${LAYERDIR_isar}/licenses/COPYING.GPLv2;md5=751419260aa954499f7abaabaa882bbe"

PROVIDES = "libubootenv-tool libubootenv-dev libubootenv-doc libubootenv0.1"

inherit dpkg

SRC_URI = "git://salsa.debian.org/debian/libubootenv.git;protocol=https;branch=master;destsuffix=${P}"
SRCREV = "32dcabeea9ed5342a2d1bb254bb4839e2e68ee5e"

DEB_BUILD_OPTIONS += "nocheck"


CHANGELOG_V ?= "${PV}+isar-${SRCREV}"

do_prepare_build() {
    deb_add_changelog
    cd ${WORKDIR}
    tar cJf ${PN}_${PV}+isar.orig.tar.xz --exclude=.git --exclude=debian ${P}
}
