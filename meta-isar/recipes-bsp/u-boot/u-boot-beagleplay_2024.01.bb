#
# This software is a part of ISAR.
# Copyright (c) Siemens AG, 2023-2024
# Copyright (C) 2025 ilbers GmbH
#
# SPDX-License-Identifier: MIT

require recipes-bsp/u-boot/u-boot-custom.inc

TI_FIRMWARE_SRCREV = "9ee2fedb1fb4815f54310dd872d34faf9948c7c1"

SRC_URI += " \
    https://ftp.denx.de/pub/u-boot/u-boot-${PV}.tar.bz2 \
    https://github.com/TexasInstruments/ti-linux-firmware/raw/${TI_FIRMWARE_SRCREV}/ti-sysfw/ti-fs-firmware-am62x-gp.bin;downloadfilename=ti-fs-firmware-am62x-gp.bin;name=sysfw \
    https://github.com/TexasInstruments/ti-linux-firmware/raw/${TI_FIRMWARE_SRCREV}/ti-sysfw/ti-fs-stub-firmware-am62x-gp.bin;downloadfilename=ti-fs-stub-firmware-am62x-gp.bin;name=sysfw-stub \
    https://github.com/TexasInstruments/ti-linux-firmware/raw/${TI_FIRMWARE_SRCREV}/ti-dm/am62xx/ipc_echo_testb_mcu1_0_release_strip.xer5f;downloadfilename=ipc_echo_testb_mcu1_0_release_strip.xer5f;name=dm \
    file://0001-TMP-board-ti-am62x-Add-basic-initialization-for-usb-.patch \
    file://rules-beagleplay"
SRC_URI[sha256sum] = "b99611f1ed237bf3541bdc8434b68c96a6e05967061f992443cb30aabebef5b3"
SRC_URI[sysfw.sha256sum] = "be7008fdf60ea7ac72d36f57a29c6a1cc6b1aa01a595eae7b3e0e927aae78e2b"
SRC_URI[sysfw-stub.sha256sum] = "1d5b23b8395037539c3b97eda2f3cc887ac2d6d0c834c9238fb727efc3c8a253"
SRC_URI[dm.sha256sum] = "6d8a1d8a8ea430efcc6effe025865df1e5eeebf572273d97e9529781e1d04663"

S = "${WORKDIR}/u-boot-${PV}"

COMPATIBLE_MACHINE = "beagleplay"

U_BOOT_BIN_INSTALL = "tiboot3-am62x-gp-evm.bin tispl.bin_unsigned u-boot.img_unsigned"

DEPENDS += "trusted-firmware-a-beagleplay optee-os-beagleplay"
DEBIAN_BUILD_DEPENDS =. "gcc-arm-linux-gnueabihf, \
    libssl-dev:native, libssl-dev, \
    swig, python3-dev:native, python3-setuptools, python3-pyelftools, \
    python3-jsonschema:native, python3-yaml:native, \
    trusted-firmware-a-beagleplay, optee-os-beagleplay,"

do_prepare_build:append() {
    mkdir -p ${S}/ti-sysfw
    cp ${WORKDIR}/ti-fs-*firmware-am62x-gp.bin ${S}/ti-sysfw
    mkdir -p ${S}/ti-dm/am62xx
    cp ${WORKDIR}/ipc_echo_testb_mcu1_0_release_strip.xer5f ${S}/ti-dm/am62xx
    cp ${WORKDIR}/rules-beagleplay ${S}/debian/rules
}
