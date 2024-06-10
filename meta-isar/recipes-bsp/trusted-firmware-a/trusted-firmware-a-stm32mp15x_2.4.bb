#
# Copyright (c) Siemens AG, 2020
#
# SPDX-License-Identifier: MIT

require recipes-bsp/trusted-firmware-a/trusted-firmware-a-custom.inc

SRC_URI += "git://github.com/ARM-software/arm-trusted-firmware.git;protocol=https;branch=master"
SRCREV = "e2c509a39c6cc4dda8734e6509cdbe6e3603cdfc"

S = "${WORKDIR}/git"

DEBIAN_BUILD_DEPENDS += ", device-tree-compiler"

TF_A_PLATFORM = "stm32mp1"
TF_A_EXTRA_BUILDARGS = " \
    ARCH=aarch32 ARM_ARCH_MAJOR=7 AARCH32_SP=optee \
    STM32MP_SDMMC=1 STM32MP_EMMC=1 \
    STM32MP_RAW_NAND=1 STM32MP_SPI_NAND=1 STM32MP_SPI_NOR=1 \
    DTB_FILE_NAME=stm32mp157c-ev1.dtb"
TF_A_BINARIES = "release/tf-a-stm32mp157c-ev1.stm32"

COMPATIBLE_MACHINE = "stm32mp15x"
