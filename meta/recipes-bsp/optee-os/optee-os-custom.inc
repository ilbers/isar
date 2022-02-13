# Custom OP-TEE OS build
#
# This software is a part of ISAR.
# Copyright (c) Siemens AG, 2020
#
# SPDX-License-Identifier: MIT

inherit dpkg

FILESEXTRAPATHS_prepend := "${FILE_DIRNAME}/files:"

SRC_URI += "file://debian/"

DESCRIPTION ?= "Custom OP-TEE OS"

OPTEE_NAME ?= "${MACHINE}"
OPTEE_PLATFORM ?= "unknown"
OPTEE_EXTRA_BUILDARGS ?= ""
OPTEE_BINARIES ?= "tee-pager_v2.bin"

DEBIAN_BUILD_DEPENDS ?= "python3-pycryptodome:native, python3-pyelftools"

PROVIDES += "optee-os-${OPTEE_NAME}"

TEMPLATE_FILES = "debian/control.tmpl debian/rules.tmpl"
TEMPLATE_VARS += "OPTEE_NAME DEBIAN_BUILD_DEPENDS OPTEE_PLATFORM OPTEE_EXTRA_BUILDARGS"

# split strip platform flavor, if any, from the specified platform string
OPTEE_PLATFORM_BASE = "${@d.getVar('OPTEE_PLATFORM').split('-')[0]}"

do_prepare_build() {
    cp -r ${WORKDIR}/debian ${S}/

    deb_add_changelog

    rm -f ${S}/debian/optee-os-${OPTEE_NAME}.install
    for binary in ${OPTEE_BINARIES}; do
        echo "out/arm-plat-${OPTEE_PLATFORM_BASE}/core/$binary /usr/lib/optee-os/${OPTEE_NAME}/" >> \
            ${S}/debian/optee-os-${OPTEE_NAME}.install
    done
}
