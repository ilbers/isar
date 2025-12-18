#
# This software is a part of ISAR.
# Copyright (c) Siemens AG, 2023-2025
# Copyright (C) 2025 ilbers GmbH
#
# SPDX-License-Identifier: MIT

inherit u-boot

TI_FIRMWARE_SRCREV = "0a37dc07b1120127eba73c7196a0b532350b9639"

SRC_URI += " \
    https://ftp.denx.de/pub/u-boot/u-boot-${PV}.tar.bz2 \
    https://github.com/TexasInstruments/ti-linux-firmware/raw/${TI_FIRMWARE_SRCREV}/ti-sysfw/ti-fs-firmware-am62x-gp.bin;downloadfilename=ti-fs-firmware-am62x-gp.bin;name=sysfw \
    https://github.com/TexasInstruments/ti-linux-firmware/raw/${TI_FIRMWARE_SRCREV}/ti-sysfw/ti-fs-stub-firmware-am62x-gp.bin;downloadfilename=ti-fs-stub-firmware-am62x-gp.bin;name=sysfw-stub \
    https://github.com/TexasInstruments/ti-linux-firmware/raw/${TI_FIRMWARE_SRCREV}/ti-dm/am62xx/ipc_echo_testb_mcu1_0_release_strip.xer5f;downloadfilename=ipc_echo_testb_mcu1_0_release_strip.xer5f;name=dm \
    file://rules-beagleplay"
SRC_URI[sha256sum] = "b4f032848e56cc8f213ad59f9132c084dbbb632bc29176d024e58220e0efdf4a"
SRC_URI[sysfw.sha256sum] = "368457718e7dc2c429db7177b31949b5d120ec97563746867fbc4883c94ee1c3"
SRC_URI[sysfw-stub.sha256sum] = "451f273b81c35b42d64e3ddfa73271dbff9da1d93f0713ec6e69bed5e836c28d"
SRC_URI[dm.sha256sum] = "0748804446dc79a8f9564f2d734d1f4346639a55e667707714c11e62766bcfce"

S = "${WORKDIR}/u-boot-${PV}"

COMPATIBLE_MACHINE = "^(beagleplay)$"

U_BOOT_BIN_INSTALL = "tiboot3-am62x-gp-evm.bin tispl.bin_unsigned u-boot.img_unsigned"

DEPENDS += "trusted-firmware-a-beagleplay optee-os-beagleplay"
DEBIAN_BUILD_DEPENDS =. "gcc-arm-linux-gnueabihf, \
    libgnutls28-dev:native, libgnutls28-dev:${DISTRO_ARCH}, \
    libssl-dev:native, libssl-dev:${DISTRO_ARCH}, \
    swig, python3-dev:native, python3-setuptools, python3-pyelftools, \
    python3-jsonschema:native, python3-yaml:native, yamllint:native, \
    trusted-firmware-a-beagleplay, optee-os-beagleplay,"

do_prepare_build:append() {
    mkdir -p ${S}/ti-sysfw
    cp ${WORKDIR}/ti-fs-*firmware-am62x-gp.bin ${S}/ti-sysfw
    mkdir -p ${S}/ti-dm/am62xx
    cp ${WORKDIR}/ipc_echo_testb_mcu1_0_release_strip.xer5f ${S}/ti-dm/am62xx
    cp ${WORKDIR}/rules-beagleplay ${S}/debian/rules
}
