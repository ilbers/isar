# Custom OP-TEE OS build
#
# This software is a part of ISAR.
# Copyright (c) Siemens AG, 2020-2023
#
# SPDX-License-Identifier: MIT

require optee-os.inc

DESCRIPTION:append = ", firmware binaries"

PROVIDES += "optee-os-${OPTEE_NAME}"

do_prepare_build:append() {
    rm -f ${S}/debian/optee-os-${OPTEE_NAME}.install
    for binary in ${OPTEE_BINARIES}; do
        echo "out/arm-plat-${OPTEE_PLATFORM_BASE}/core/$binary /usr/lib/optee-os/${OPTEE_NAME}/" >> \
            ${S}/debian/optee-os-${OPTEE_NAME}.install
    done
}
