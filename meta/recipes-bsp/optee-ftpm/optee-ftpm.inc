# Copyright (c) Siemens AG, 2023
#
# Authors:
#  Su Bao Cheng <baocheng.su@siemens.com>
#
# SPDX-License-Identifier: MIT
#
inherit dpkg

SUMMARY = "OPTEE fTPM Microsoft TA"
DESCRIPTION = "TCG reference implementation of the TPM 2.0 Specification."
HOMEPAGE = "https://github.com/microsoft/ms-tpm-20-ref/"

FILESEXTRAPATHS:prepend := "${FILE_DIRNAME}/files:"

SRC_URI += "file://debian"

OPTEE_NAME ?= "${MACHINE}"

DEPENDS = "optee-os-tadevkit-${OPTEE_NAME}"
DEBIAN_BUILD_DEPENDS ?= " \
    python3-cryptography:native,                                        \
    optee-os-tadevkit-${OPTEE_NAME}                                     \
    "

TA_CPU ?= "unknown"
TA_DEV_KIT_DIR ?= "unknown"
OPTEE_FTPM_BUILD_ARGS_EXTRA ?= " "

TEMPLATE_FILES = "debian/rules.tmpl debian/control.tmpl"
TEMPLATE_VARS += "DEBIAN_BUILD_DEPENDS \
    OPTEE_FTPM_BUILD_ARGS_EXTRA \
    TA_CPU \
    TA_DEV_KIT_DIR"

do_prepare_build() {
    rm -rf ${S}/debian
    cp -r ${WORKDIR}/debian ${S}/

    deb_add_changelog

    rm -f ${S}/debian/optee-ftpm-${OPTEE_NAME}.install
    echo "Samples/ARM32-FirmwareTPM/optee_ta/out/fTPM/bc50d971-d4c9-42c4-82cb-343fb7f37896.ta /usr/lib/optee-os/${OPTEE_NAME}/ta" > \
        ${S}/debian/optee-ftpm-${OPTEE_NAME}.install
    echo "Samples/ARM32-FirmwareTPM/optee_ta/out/fTPM/bc50d971-d4c9-42c4-82cb-343fb7f37896.stripped.elf /usr/lib/optee-os/${OPTEE_NAME}/ta" >> \
        ${S}/debian/optee-ftpm-${OPTEE_NAME}.install
}
