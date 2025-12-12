# Copyright (c) Siemens AG, 2023-2025
#
# Authors:
#  Su Bao Cheng <baocheng.su@siemens.com>
#  Jan Kiszka <jan.kiszka@siemens.com>
#
# SPDX-License-Identifier: MIT
#

inherit dpkg

SUMMARY = "OP-TEE fTPM TA"
DESCRIPTION = "Firmware TPM as OP-TEE TCG TA, using Microsoft's TPM 2.0 reference implementation"
HOMEPAGE = "https://github.com/OP-TEE/optee_ftpm"

FILESPATH:append = ":${LAYERDIR_core}/recipes-bsp/optee-ftpm/files"

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

# Set to the subdir in WORKDIR containing the unpacked ms-tpm-20-ref sources
# Leave empty for if still using ms-tpm-20-ref for OP-TEE TA integration
MS_TPM_20_REF_DIR ?= ""

OPTEE_FTPM_SRCDIR = "${@'Samples/ARM32-FirmwareTPM/optee_ta' if d.getVar('MS_TPM_20_REF_DIR') == '' else '.'}"
OPTEE_FTPM_BINDIR = "${@'Samples/ARM32-FirmwareTPM/optee_ta/fTPM' if d.getVar('MS_TPM_20_REF_DIR') == '' else '.'}"

TEMPLATE_FILES = "debian/rules.tmpl debian/control.tmpl"
TEMPLATE_VARS += "DEBIAN_BUILD_DEPENDS \
    DEBIAN_COMPAT \
    OPTEE_FTPM_BUILD_ARGS_EXTRA \
    TA_CPU \
    TA_DEV_KIT_DIR \
    MS_TPM_20_REF_DIR \
    OPTEE_FTPM_SRCDIR \
    DEBIAN_STANDARDS_VERSION"

do_prepare_build() {
    rm -rf "${S}/debian"
    cp -r "${WORKDIR}/debian" "${S}/"

    deb_add_changelog

    rm -f ${S}/debian/optee-ftpm-${OPTEE_NAME}.install
    echo "${OPTEE_FTPM_BINDIR}/out/bc50d971-d4c9-42c4-82cb-343fb7f37896.ta /usr/lib/optee-os/${OPTEE_NAME}/ta" > \
        ${S}/debian/optee-ftpm-${OPTEE_NAME}.install
    echo "${OPTEE_FTPM_BINDIR}/out/bc50d971-d4c9-42c4-82cb-343fb7f37896.stripped.elf /usr/lib/optee-os/${OPTEE_NAME}/ta" >> \
        ${S}/debian/optee-ftpm-${OPTEE_NAME}.install

    if [ -n "${MS_TPM_20_REF_DIR}" ] && [ -e "${WORKDIR}/${MS_TPM_20_REF_DIR}" ]; then
        rm -rf "${S}/${MS_TPM_20_REF_DIR}"
        cp -a "${WORKDIR}/${MS_TPM_20_REF_DIR}" "${S}/"
    fi
}
