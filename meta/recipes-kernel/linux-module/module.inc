# Custom kernel module recipe include
#
# This software is a part of ISAR.
# Copyright (c) Siemens AG, 2018
#
# SPDX-License-Identifier: MIT

FILESPATH:append := ":${FILE_DIRNAME}/files"

DESCRIPTION ?= "Custom kernel module ${PN}"

KERNEL_NAME ?= ""
# directory with KBuild file (M=${MODULE_DIR})
MODULE_DIR ?= "$(PWD)"

PN .= "-${KERNEL_NAME}"

KERNEL_IMAGE_PKG ??= "linux-image-${KERNEL_NAME}"
KERNEL_HEADERS_PKG ??= "linux-headers-${KERNEL_NAME}"
DEPENDS += "${KERNEL_HEADERS_PKG}"
DEBIAN_BUILD_DEPENDS = "${KERNEL_HEADERS_PKG}"

SIGNATURE_KEYFILE ??= ""
SIGNATURE_CERTFILE ??= ""
SIGNATURE_HASHFN ??= "sha256"

SRC_URI += "file://debian/"

AUTOLOAD ?= ""

inherit dpkg

TEMPLATE_FILES = "debian/control.tmpl \
                  debian/changelog.tmpl \
                  debian/rules.tmpl"
TEMPLATE_VARS += " \
    KERNEL_NAME \
    KERNEL_TYPE \
    KERNEL_IMAGE_PKG \
    KERNEL_HEADERS_PKG \
    MODULE_DIR \
    DEBIAN_BUILD_DEPENDS \
    SIGNATURE_KEYFILE \
    SIGNATURE_CERTFILE \
    SIGNATURE_HASHFN \
    PN"

do_prepare_build() {
    rm -rf ${S}/debian
    cp -r ${WORKDIR}/debian ${S}/

    for module in ${AUTOLOAD}; do
        echo "echo $module >> /etc/modules" >> ${S}/debian/postinst
    done
}
