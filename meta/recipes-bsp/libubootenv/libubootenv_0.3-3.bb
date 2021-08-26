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

inherit dpkg-gbp

SRC_URI = "git://salsa.debian.org/debian/libubootenv.git;protocol=https"
SRCREV = "a1a3504e5cda1883928a8747a0bedc56afff6910"

S = "${WORKDIR}/git"


dpkg_runbuild_prepend() {
	export DEB_BUILD_OPTIONS="nocheck"
}
