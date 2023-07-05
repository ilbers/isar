# Copyright (c) Siemens AG, 2023
#
# Authors:
#  Su Bao Cheng <baocheng.su@siemens.com>
#
# SPDX-License-Identifier: MIT
#
require recipes-bsp/optee-ftpm/optee-ftpm.inc

# CHANGELOG_V = "0.1+git+isar"

SRC_URI += " \
    https://github.com/Microsoft/ms-tpm-20-ref/archive/${SRCREV}.tar.gz \
    https://github.com/wolfSSL/wolfssl/archive/${SRCREV-wolfssl}.tar.gz;name=wolfssl \
    file://0001-add-enum-to-ta-flags.patch \
    "

SRCREV = "f74c0d9686625c02b0fdd5b2bbe792a22aa96cb6"
# according to ms-tpm-20-ref submodules
SRCREV-wolfssl = "9c87f979a7f1d3a6d786b260653d566c1d31a1c4"

SRC_URI[sha256sum] = "16fabc6ad6cc700d947dbc96efc30ff8ae97e577944466f08193bb37bc1eb64d"
SRC_URI[wolfssl.sha256sum] = "a68c301fa0ee6197158912d808c4258605a2d001e458fd958257cafba17bfd14"

S = "${WORKDIR}/ms-tpm-20-ref-${SRCREV}"

OPTEE_NAME = "${MACHINE}"
TA_CPU = "cortex-a7"
TA_DEV_KIT_DIR = "/usr/lib/optee-os/${OPTEE_NAME}/export-ta_arm32"
OPTEE_FTPM_BUILD_ARGS_EXTRA = "CFG_FTPM_USE_WOLF=y"

do_prepare_build:append() {
    rm -rf ${S}/external/wolfssl
    cp -a ${S}/../wolfssl-${SRCREV-wolfssl} ${S}/external/wolfssl
}
