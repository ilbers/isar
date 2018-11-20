# Custom U-Boot build
#
# This software is a part of ISAR.
# Copyright (c) Siemens AG, 2018
#
# SPDX-License-Identifier: MIT

FILESPATH =. "${LAYERDIR_core}/recipes-bsp/u-boot/files:"

DESCRIPTION ?= "Custom U-Boot"

PROVIDES += "${PN}-${MACHINE} ${PN}-${MACHINE}-dev ${PN}-tools"

inherit dpkg

SRC_URI += "file://debian/"

U_BOOT_BUILD_DEPENDS ?= "bc, bison, flex, device-tree-compiler"

do_prepare_build() {
    cp -r ${WORKDIR}/debian ${S}/
    sed -i -e 's/@PN@/${PN}/g' -e 's/@PV@/${PV}/g' \
        -e 's/@BUILD_DEPENDS@/${U_BOOT_BUILD_DEPENDS}/g' \
        -e 's/@MACHINE@/${MACHINE}/g' \
        -e 's/@DISTRO_ARCH@/${DISTRO_ARCH}/g' \
        -e 's/@DESCRIPTION@/${DESCRIPTION}/g' \
        ${S}/debian/changelog ${S}/debian/control

    echo "${U_BOOT_BIN} /usr/lib/u-boot/${MACHINE}" > \
        ${S}/debian/u-boot-${MACHINE}.install

    echo "tools/env/libubootenv.a usr/lib" > \
        ${S}/debian/u-boot-${MACHINE}-dev.install
}

dpkg_runbuild_prepend() {
    export U_BOOT_CONFIG=${U_BOOT_CONFIG}
    export U_BOOT_BIN=${U_BOOT_BIN}
}
