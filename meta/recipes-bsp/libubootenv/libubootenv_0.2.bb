# libubootenv
#
# This software is a part of ISAR.
# Copyright (c) Siemens AG, 2020
#
# SPDX-License-Identifier: MIT

DESCRIPTION = "swupdate utility for software updates"
HOMEPAGE= "https://github.com/sbabic/swupdate"
LICENSE = "GPL-2.0"
LIC_FILES_CHKSUM = "file://${LAYERDIR_isar}/licenses/COPYING.GPLv2;md5=751419260aa954499f7abaabaa882bbe"

PROVIDES = "libubootenv-tool libubootenv-dev libubootenv-doc libubootenv0.1"

inherit dpkg-gbp

SRC_URI = "git://salsa.debian.org/debian/libubootenv.git;protocol=https \
           file://0002-Add-support-GNUInstallDirs.patch;apply=no "
SRCREV = "2c7cb6d941d906dcc1d2e447cc17e418485dff12"

S = "${WORKDIR}/git"

do_prepare_build() {
	cd ${S}
	export QUILT_PATCHES=debian/patches
	quilt import -f ${WORKDIR}/*.patch
	quilt push -a
}

dpkg_runbuild_prepend() {
	export DEB_BUILD_OPTIONS="nocheck"
}
