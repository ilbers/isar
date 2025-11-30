# Custom Trusted Firmware A build
#
# This software is a part of ISAR.
# Copyright (c) Siemens AG, 2020-2025
#
# SPDX-License-Identifier: MIT

inherit dpkg

FILESPATH:append = ":${LAYERDIR_core}/recipes-bsp/trusted-firmware-a/files"
SRC_URI += "file://debian/"

DESCRIPTION ?= "Custom Trusted Firmware A"

TF_A_NAME ?= "${MACHINE}"
TF_A_PLATFORM ?= "unknown"
TF_A_EXTRA_BUILDARGS ?= ""
TF_A_BINARIES ?= "release/bl31.bin"

DEBIAN_BUILD_DEPENDS ?= ""

PROVIDES += "trusted-firmware-a-${TF_A_NAME}"

TEMPLATE_FILES = "debian/control.tmpl debian/rules.tmpl"
TEMPLATE_VARS += " \
    DEBIAN_COMPAT \
    DEBIAN_STANDARDS_VERSION \
    DEBIAN_BUILD_DEPENDS \
    TF_A_NAME \
    TF_A_PLATFORM \
    TF_A_EXTRA_BUILDARGS"

do_prepare_build() {
    cp -r ${WORKDIR}/debian ${S}/

    deb_add_changelog

    rm -f ${S}/debian/trusted-firmware-a-${TF_A_NAME}.install
    for binary in ${TF_A_BINARIES}; do
        echo "build/${TF_A_PLATFORM}/$binary /usr/lib/trusted-firmware-a/${TF_A_NAME}/" >> \
            ${S}/debian/trusted-firmware-a-${TF_A_NAME}.install
    done
}
