#
# Copyright (c) Siemens AG, 2020-2023
#
# SPDX-License-Identifier: MIT

require recipes-bsp/optee-os/optee-os-custom.inc
require optee-os-stm32mp15x_${PV}.inc

# optee-examples integration
DEPENDS += "optee-examples-stm32mp15x"
DEBIAN_BUILD_DEPENDS += " \
    , optee-examples-stm32mp15x-acipher-ta \
    , optee-examples-stm32mp15x-aes-ta \
    , optee-examples-stm32mp15x-hello-world-ta \
    , optee-examples-stm32mp15x-hotp-ta \
    , optee-examples-stm32mp15x-random-ta \
    , optee-examples-stm32mp15x-secure-storage-ta \
    "
EARLY_TA_PATHS += " \
    /usr/lib/optee-os/${OPTEE_NAME}/ta/a734eed9-d6a1-4244-aa50-7c99719e7b7b.stripped.elf \
    /usr/lib/optee-os/${OPTEE_NAME}/ta/5dbac793-f574-4871-8ad3-04331ec17f24.stripped.elf \
    /usr/lib/optee-os/${OPTEE_NAME}/ta/8aaaf200-2450-11e4-abe2-0002a5d5c51b.stripped.elf \
    /usr/lib/optee-os/${OPTEE_NAME}/ta/484d4143-2d53-4841-3120-4a6f636b6542.stripped.elf \
    /usr/lib/optee-os/${OPTEE_NAME}/ta/b6c53aba-9669-4668-a7f2-205629d00f86.stripped.elf \
    /usr/lib/optee-os/${OPTEE_NAME}/ta/f4e750bb-1437-4fbf-8785-8d3580c34994.stripped.elf \
    "

# optee-ftpm integration
DEPENDS += "optee-ftpm-stm32mp15x"
DEBIAN_BUILD_DEPENDS += ", optee-ftpm-stm32mp15x"
EARLY_TA_PATHS += " \
    /usr/lib/optee-os/${OPTEE_NAME}/ta/bc50d971-d4c9-42c4-82cb-343fb7f37896.stripped.elf \
    "

OPTEE_EXTRA_BUILDARGS += " \
    CFG_EARLY_TA=y \
    EARLY_TA_PATHS='${EARLY_TA_PATHS}' \
    "
