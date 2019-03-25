# Custom U-Boot build
#
# This software is a part of ISAR.
# Copyright (c) Siemens AG, 2018
#
# SPDX-License-Identifier: MIT

FILESPATH =. "${LAYERDIR_core}/recipes-bsp/u-boot/files:"

DESCRIPTION ?= "Custom U-Boot"

PROVIDES += "u-boot-${MACHINE} u-boot-${MACHINE}-dev u-boot-tools"

inherit dpkg

SRC_URI += "file://debian/"

BUILD_DEPENDS ?= "bc, bison, flex, device-tree-compiler, git"

TEMPLATE_FILES = "debian/changelog.tmpl \
                  debian/control.tmpl"
TEMPLATE_VARS += "MACHINE BUILD_DEPENDS"

do_prepare_build() {
    cp -r ${WORKDIR}/debian ${S}/

    echo "${U_BOOT_BIN} /usr/lib/u-boot/${MACHINE}" > \
        ${S}/debian/u-boot-${MACHINE}.install

    echo "tools/env/libubootenv.a usr/lib" > \
        ${S}/debian/u-boot-${MACHINE}-dev.install
}

dpkg_runbuild_prepend() {
    export U_BOOT_CONFIG=${U_BOOT_CONFIG}
    export U_BOOT_BIN=${U_BOOT_BIN}
}
