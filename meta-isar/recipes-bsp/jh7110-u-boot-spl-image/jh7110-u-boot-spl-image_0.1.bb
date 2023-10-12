#
# Copyright (c) Siemens AG, 2023
#
# SPDX-License-Identifier: MIT

inherit dpkg

SRC_URI = "file://rules file://install"

DESCRIPTION = "StarFive VisionFive 2 u-boot SPL"
DEPENDS = "jh7110-u-boot-spl-tool-native u-boot-starfive-visionfive2"
DEBIAN_BUILD_DEPENDS = "jh7110-u-boot-spl-tool:native, u-boot-starfive-visionfive2:${DISTRO_ARCH}"

# this is a host tool
PACKAGE_ARCH = "${BUILD_ARCH}"

do_prepare_build[cleandirs] += "${S}/debian"
do_prepare_build(){
    deb_debianize
    cp ${WORKDIR}/install ${S}/debian/
}

do_deploy() {
    dpkg --fsys-tarfile ${WORKDIR}/jh7110-u-boot-spl-image_${PV}*.deb | \
        tar xOf - "./usr/share/jh7110-uboot-spl-image/u-boot-spl.bin.normal.out" \
        > "${DEPLOY_DIR_IMAGE}/u-boot-spl.bin.normal.out"
}

addtask deploy after do_dpkg_build before do_build
do_deploy[dirs] = "${DEPLOY_DIR_IMAGE}"

COMPATIBLE_MACHINE = "starfive-visionfive2"
