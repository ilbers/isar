#
# Copyright (c) Siemens AG, 2020
#
# SPDX-License-Identifier: MIT

require recipes-bsp/trusted-firmware-a/trusted-firmware-a-custom.inc

SRC_URI += "https://git.trustedfirmware.org/TF-A/trusted-firmware-a.git/snapshot/trusted-firmware-a-${PV}.tar.gz"
SRC_URI[sha256sum] = "bf3eb3617a74cddd7fb0e0eacbfe38c3258ee07d4c8ed730deef7a175cc3d55b"

S = "${WORKDIR}/trusted-firmware-a-${PV}"

DEBIAN_BUILD_DEPENDS += ", device-tree-compiler"

TF_A_PLATFORM = "stm32mp1"
TF_A_EXTRA_BUILDARGS = " \
    ARCH=aarch32 ARM_ARCH_MAJOR=7 AARCH32_SP=optee \
    STM32MP_SDMMC=1 STM32MP_EMMC=1 \
    STM32MP_RAW_NAND=1 STM32MP_SPI_NAND=1 STM32MP_SPI_NOR=1 \
    DTB_FILE_NAME=stm32mp157c-ev1.dtb"
TF_A_BINARIES = "release/tf-a-stm32mp157c-ev1.stm32"

COMPATIBLE_MACHINE = "stm32mp15x"
