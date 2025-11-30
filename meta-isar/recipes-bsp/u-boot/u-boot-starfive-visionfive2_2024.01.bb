#
# Copyright (c) Siemens AG, 2023-2025
#
# SPDX-License-Identifier: MIT

inherit u-boot

COMPATIBLE_MACHINE = "starfive-visionfive2"

SRC_URI += "https://ftp.denx.de/pub/u-boot/u-boot-${PV}.tar.bz2 \
    file://0001-scripts-dtc-pylibfdt-libfdt.i_shipped-Use-SWIG_Appen.patch \
    file://starfive-visionfive2-rules.tmpl"
SRC_URI[sha256sum] = "b99611f1ed237bf3541bdc8434b68c96a6e05967061f992443cb30aabebef5b3"

DEPENDS += "opensbi-starfive-visionfive2 jh7110-u-boot-spl-tool-native"
DEBIAN_BUILD_DEPENDS .= ", opensbi-starfive-visionfive2, \
    jh7110-u-boot-spl-tool:native, \
    swig, python3-dev:native, python3-setuptools, \
    libssl-dev:${DISTRO_ARCH}, libssl-dev:native"

U_BOOT_CONFIG = "starfive_visionfive2_defconfig"
U_BOOT_BIN = "u-boot.itb spl/u-boot-spl.bin.normal.out"

TEMPLATE_FILES += "starfive-visionfive2-rules.tmpl"

S = "${WORKDIR}/u-boot-${PV}"

do_prepare_build:append() {
	cp ${WORKDIR}/starfive-visionfive2-rules ${S}/debian/rules
}
