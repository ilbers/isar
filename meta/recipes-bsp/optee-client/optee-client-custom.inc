#
# Copyright (c) Siemens AG, 2023-2025
#
# Authors:
#  Su Bao Cheng <baocheng.su@siemens.com>
#
# SPDX-License-Identifier: MIT
#

inherit dpkg

FILESPATH:append := ":${FILE_DIRNAME}/files"

DESCRIPTION = "OPTee Client"

PROVIDES = "libteec1 libckteec0 libseteec0 libteeacl0.1.0"
PROVIDES += "optee-client-dev tee-supplicant"

SRC_URI += "file://debian"

TEE_FS_PARENT_PATH ?= "/var/lib/optee-client/data/tee"
# To use the builtin RPMB emulation, change to 1
RPMB_EMU ?= "0"

TEMPLATE_FILES = "debian/rules.tmpl debian/control.tmpl"
TEMPLATE_VARS += "DEBIAN_COMPAT TEE_FS_PARENT_PATH RPMB_EMU DEBIAN_STANDARDS_VERSION"

do_prepare_build[cleandirs] += "${S}/debian"
do_prepare_build() {
    cp -r ${WORKDIR}/debian ${S}/

    deb_add_changelog

    echo "/usr/sbin/*" > ${S}/debian/tee-supplicant.install
    echo "lib/optee_armtz/" > ${S}/debian/tee-supplicant.dirs
    echo "usr/lib/tee-supplicant/plugins/" >> ${S}/debian/tee-supplicant.dirs

    echo "usr/lib/*/libteec*.so.*" > ${S}/debian/libteec1.install

    echo "usr/include/*" > ${S}/debian/optee-client-dev.install
    echo "usr/lib/*/lib*.so" >> ${S}/debian/optee-client-dev.install
}
