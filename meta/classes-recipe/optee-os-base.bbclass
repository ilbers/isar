# Custom OP-TEE OS build
#
# This software is a part of ISAR.
# Copyright (c) Siemens AG, 2020-2025
#
# SPDX-License-Identifier: MIT

inherit dpkg

FILESPATH:append = ":${LAYERDIR_core}/recipes-bsp/optee-os/files"
SRC_URI += "file://debian/"

DESCRIPTION ?= "Custom OP-TEE OS"

OPTEE_NAME ?= "${MACHINE}"
OPTEE_PLATFORM ?= "unknown"
OPTEE_EXTRA_BUILDARGS ?= ""
OPTEE_BINARIES ?= "tee-raw.bin"

DEBIAN_PACKAGE_NAME ?= "optee-os-${OPTEE_NAME}"

DEBIAN_BUILD_DEPENDS ?= "python3-pycryptodome:native, python3-pyelftools"

TEMPLATE_FILES = "debian/control.tmpl debian/rules.tmpl"
TEMPLATE_VARS += "DEBIAN_COMPAT DEBIAN_PACKAGE_NAME OPTEE_NAME DEBIAN_BUILD_DEPENDS OPTEE_PLATFORM OPTEE_EXTRA_BUILDARGS DEBIAN_STANDARDS_VERSION"

# split strip platform flavor, if any, from the specified platform string
OPTEE_PLATFORM_BASE = "${@d.getVar('OPTEE_PLATFORM').split('-')[0]}"

do_prepare_build() {
    cp -r ${WORKDIR}/debian ${S}/

    deb_add_changelog
}
