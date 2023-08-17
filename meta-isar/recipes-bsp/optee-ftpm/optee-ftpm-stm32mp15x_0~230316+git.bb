# Copyright (c) Siemens AG, 2023
#
# Authors:
#  Su Bao Cheng <baocheng.su@siemens.com>
#
# SPDX-License-Identifier: MIT
#

require recipes-bsp/optee-ftpm/optee-ftpm.inc

SRC_URI += " \
    https://github.com/Microsoft/ms-tpm-20-ref/archive/${SRCREV}.tar.gz \
    https://github.com/wolfSSL/wolfssl/archive/${SRCREV-wolfssl}.tar.gz;name=wolfssl \
    file://0001-add-enum-to-ta-flags.patch \
    file://0001-Fix-parallel-build-of-optee_ta.patch \
    "

SRCREV = "f74c0d9686625c02b0fdd5b2bbe792a22aa96cb6"
SRCREV-wolfssl = "3b3c175af0e993ffaae251871421e206cc41963f"

SRC_URI[sha256sum] = "16fabc6ad6cc700d947dbc96efc30ff8ae97e577944466f08193bb37bc1eb64d"
SRC_URI[wolfssl.sha256sum] = "1157994b12295b74754dd9054124c857c59093b762e6f744d0a3a3565cb6314d"

S = "${WORKDIR}/ms-tpm-20-ref-${SRCREV}"

TA_CPU = "cortex-a7"
TA_DEV_KIT_DIR = "/usr/lib/optee-os/${OPTEE_NAME}/export-ta_arm32"

do_prepare_build:append() {
    rm -rf ${S}/external/wolfssl
    cp -a ${S}/../wolfssl-${SRCREV-wolfssl} ${S}/external/wolfssl
}

COMPATIBLE_MACHINE = "stm32mp15x"
