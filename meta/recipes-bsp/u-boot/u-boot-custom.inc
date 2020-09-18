# Custom U-Boot build
#
# This software is a part of ISAR.
# Copyright (c) Siemens AG, 2018
#
# SPDX-License-Identifier: MIT

FILESEXTRAPATHS_prepend := "${FILE_DIRNAME}/files:"

DESCRIPTION ?= "Custom U-Boot"

PROVIDES += "u-boot-${MACHINE} u-boot-${MACHINE}-dev"
PROVIDES += "${@'u-boot-tools' if d.getVar('U_BOOT_TOOLS_PACKAGE') == '1' else ''}"
PROVIDES += "${@('u-boot-config u-boot-' + d.getVar('MACHINE') + '-config') \
    if d.getVar('U_BOOT_CONFIG_PACKAGE') == '1' else ''}"

inherit dpkg

SRC_URI += "file://debian/"

BUILD_DEPENDS ?= "bc, bison, flex, device-tree-compiler, git"

TEMPLATE_FILES = "debian/control.tmpl"
TEMPLATE_VARS += "MACHINE BUILD_DEPENDS"

U_BOOT_TOOLS_PACKAGE ?= "0"
U_BOOT_CONFIG_PACKAGE ?= "0"

do_prepare_build() {
    cp -r ${WORKDIR}/debian ${S}/

    deb_add_changelog

    echo "${U_BOOT_BIN} /usr/lib/u-boot/${MACHINE}" > \
        ${S}/debian/u-boot-${MACHINE}.install

    echo "tools/env/libubootenv.a usr/lib" > \
        ${S}/debian/u-boot-${MACHINE}-dev.install

    if [ "${U_BOOT_TOOLS_PACKAGE}" = "1" ]; then
        cat <<EOF >>${S}/debian/control

Package: u-boot-tools
Architecture: linux-any
Depends: \${shlibs:Depends}, \${misc:Depends}
Description: ${DESCRIPTION}, companion tools
EOF
    fi

    if [ "${U_BOOT_CONFIG_PACKAGE}" = "1" ]; then
        cp ${WORKDIR}/fw_env.config ${S}/ || \
            die "U_BOOT_CONFIG_PACKAGE requires a fw_env.config in SRC_URI"

        cat <<EOF >>${S}/debian/control

Package: u-boot-${MACHINE}-config
Provides: u-boot-config
Architecture: ${DISTRO_ARCH}
Description: ${DESCRIPTION}, environment configuration
EOF

        cat <<EOF >>${S}/debian/u-boot-${MACHINE}-config.install
u-boot-initial-env /etc
fw_env.config      /etc
EOF
    fi
}

dpkg_runbuild_prepend() {
    export U_BOOT_CONFIG="${U_BOOT_CONFIG}"
    export U_BOOT_BIN="${U_BOOT_BIN}"
}
