#
# Copyright (c) Siemens AG, 2020
#
# SPDX-License-Identifier: MIT

require recipes-bsp/trusted-firmware-a/trusted-firmware-a-custom.inc

SRC_URI += "https://git.trustedfirmware.org/TF-A/trusted-firmware-a.git/snapshot/trusted-firmware-a-${PV}.tar.gz"
SRC_URI[sha256sum] = "37f917922bcef181164908c470a2f941006791c0113d738c498d39d95d543b21"

S = "${WORKDIR}/trusted-firmware-a-${PV}"

DEBIAN_BUILD_DEPENDS += ", device-tree-compiler"

TF_A_PLATFORM = "stm32mp1"
TF_A_EXTRA_BUILDARGS = " \
    ARCH=aarch32 ARM_ARCH_MAJOR=7 AARCH32_SP=optee \
    STM32MP_SDMMC=1 STM32MP_EMMC=1 \
    STM32MP_RAW_NAND=1 STM32MP_SPI_NAND=1 STM32MP_SPI_NOR=1 \
    DTB_FILE_NAME=stm32mp157c-ev1.dtb"
TF_A_BINARIES = "release/tf-a-stm32mp157c-ev1.stm32"
