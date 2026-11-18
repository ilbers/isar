#
# Copyright (c) Siemens AG, 2020-2025
# Copyright (c) 2023-2026 ilbers GmbH
#
# SPDX-License-Identifier: MIT

inherit trusted-firmware-a

MAINTAINER = "isar-users <isar-users@googlegroups.com>"

SRC_URI += "https://github.com/ARM-software/arm-trusted-firmware/archive/v${PV}.tar.gz;downloadfilename=arm-trusted-firmware-${PV}.tar.gz \
    file://0001-feat-stm32mp15-fdts-add-stm32mp157d-dk1-board.patch \
    file://0001-feat-stm32mp15-fdts-fulfill-diversity-for-STM32M15x-.patch \
    file://0001-feat-build-add-support-for-new-binutils-versions.patch"

SRC_URI[sha256sum] = "42256fa354f32b09972e72e0570a0f73698785927f93163b1d1308c485fcb4a6"

S = "${WORKDIR}/arm-trusted-firmware-${PV}"

DEPENDS = "u-boot-${MACHINE} optee-os-${MACHINE}"

DEBIAN_BUILD_DEPENDS += ", optee-os-${MACHINE}, u-boot-${MACHINE}, \
    device-tree-compiler, git, libssl-dev:native"

TF_A_PLATFORM = "stm32mp1"

FIP_EXTRA_BUILDARGS = "AARCH32_SP=optee \
    BL32=/usr/lib/optee-os/${MACHINE}/tee-header_v2.bin \
    BL32_EXTRA1=/usr/lib/optee-os/${MACHINE}/tee-pager_v2.bin \
    BL32_EXTRA2=/usr/lib/optee-os/${MACHINE}/tee-pageable_v2.bin \
    BL33=/usr/lib/u-boot/${MACHINE}/u-boot-nodtb.bin \
    BL33_CFG=/usr/lib/u-boot/${MACHINE}/u-boot.dtb \
    FW_CONFIG=fdts/stm32mp157d-dk1-fw-config.dts \
    all fip"

TF_A_EXTRA_BUILDARGS = " \
    ARCH=aarch32 ARM_ARCH_MAJOR=7 \
    STM32MP_SDMMC=1 DTB_FILE_NAME=stm32mp157d-dk1.dtb \
    ${FIP_EXTRA_BUILDARGS}"

TF_A_BINARIES = "release/tf-a-stm32mp157d-dk1.stm32 release/fip.bin"

COMPATIBLE_MACHINE = "^(stm32mp15x)$"
