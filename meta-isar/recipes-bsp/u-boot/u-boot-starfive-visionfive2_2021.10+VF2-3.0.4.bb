#
# Copyright (c) Siemens AG, 2023
#
# SPDX-License-Identifier: MIT

require recipes-bsp/u-boot/u-boot-custom.inc

SRC_URI += "git://github.com/starfive-tech/u-boot.git;nobranch=1;protocol=https;destsuffix=u-boot-${PV}"
SRCREV = "b6e2b0e85c774a18ae668223a6e5f7d335895243"

DEBIAN_BUILD_DEPENDS .= ", libssl-dev:${DISTRO_ARCH}"
# when cross compiling, we need the library on the host as well, as the signature computation is done locally
DEBIAN_BUILD_DEPENDS .= "${@ ', libssl-dev:${HOST_ARCH}' if d.getVar('ISAR_CROSS_COMPILE') == '1' else '' }"

U_BOOT_CONFIG = "starfive_visionfive2_defconfig"
U_BOOT_BIN = "u-boot.bin"
U_BOOT_SPL_BIN = "spl/u-boot-spl.bin"

S = "${WORKDIR}/u-boot-${PV}"

# install dtb files for opensbi
do_prepare_build[cleandirs] += "${S}/debian"
do_prepare_build:append() {
    # also build and install spl component
    sed -i 's|${U_BOOT_BIN}|${U_BOOT_BIN} ${U_BOOT_SPL_BIN}|g' ${S}/debian/rules
    echo "${U_BOOT_SPL_BIN} usr/lib/u-boot/${MACHINE}/" \
        >> ${S}/debian/u-boot-${MACHINE}.install
    # install device tree
    echo "arch/riscv/dts/*.dtb usr/share/u-boot/${MACHINE}/" \
        >> ${S}/debian/u-boot-${MACHINE}-dev.install
}

COMPATIBLE_MACHINE = "starfive-visionfive2"
