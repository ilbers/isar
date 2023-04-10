#
# Copyright (c) Siemens AG, 2023
#
# SPDX-License-Identifier: MIT

inherit dpkg

DESCRIPTION = "VisionFive2 SDK spl_tool"
LICENSE = "CPL-1"

SRC_URI = "git://github.com/starfive-tech/Tools.git;branch=master;protocol=https;destsuffix=tools"
SRCREV = "8c5acc4e5eb7e4ad012463b05a5e3dbbfed1c38d"

S = "${WORKDIR}/tools/spl_tool"

# This is a host tool
PACKAGE_ARCH = "${HOST_ARCH}"

do_prepare_build[cleandirs] += "${S}/debian"
do_prepare_build(){
    deb_debianize
    echo "spl_tool usr/lib/jh7110-uboot-spl-tool" > ${S}/debian/${PN}.install
}
