# Custom OP-TEE OS build for TA devkit
#
# This software is a part of ISAR.
# Copyright (c) Siemens AG, 2023
#
# SPDX-License-Identifier: MIT

require optee-os.inc

DEBIAN_PACKAGE_NAME = "optee-os-tadevkit-${OPTEE_NAME}"
DESCRIPTION:append = ", trust application development kit."

PROVIDES += "${DEBIAN_PACKAGE_NAME}"

do_prepare_build:append() {
    if [ "${DISTRO_ARCH}" = "arm64" ]; then
        TADEVKIT_DIR="export-ta_arm64"
    elif [ "${DISTRO_ARCH}" = "armhf" ]; then
        TADEVKIT_DIR="export-ta_arm32"
    else
        bbfatal "${DISTRO_ARCH} does not have a compat arch for optee TA devkit!"
    fi

    echo "out/arm-plat-${OPTEE_PLATFORM_BASE}/${TADEVKIT_DIR} /usr/lib/optee-os/${OPTEE_NAME}/" > \
        ${S}/debian/optee-os-tadevkit-${OPTEE_NAME}.install
}
