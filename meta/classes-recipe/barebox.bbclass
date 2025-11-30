# This software is a part of ISAR.
# Copyright (C) 2022 ilbers GmbH
# Copyright (c) Siemens, 2025
#
# SPDX-License-Identifier: MIT

inherit dpkg

DESCRIPTION ?= "The barebox is a bootloader designed for embedded systems. It \
                runs on a variety of architectures including x86, ARM, MIPS, \
                PowerPC and others."
CHANGELOG_V = "${PV}+${PR}"
MAINTAINER ?= "isar-users <isar-users@googlegroups.com>"

DEBIAN_BUILD_DEPENDS ?= "lzop, coreutils, bison, flex, lz4"

BAREBOX_CONFIG ?= ""
BAREBOX_BUILD_DIR ?= "build"
BAREBOX_VERSION_EXTENSION ?= ""
BAREBOX_ENV ?= ""

FILESPATH:append = ":${LAYERDIR_core}/recipes-bsp/barebox/files"
SRC_URI += "file://rules.tmpl \
            file://version.cfg.tmpl \
            file://defaultenv.cfg.tmpl"

BAREBOX_CONFIG_FRAGMENTS = "version.cfg defaultenv.cfg"

SRC_URI += "${@'file://%s' % d.getVar('BAREBOX_ENV') if d.getVar('BAREBOX_ENV') else ''}"

TEMPLATE_FILES += "rules.tmpl version.cfg.tmpl defaultenv.cfg.tmpl"
TEMPLATE_VARS += "BAREBOX_CONFIG BAREBOX_BUILD_DIR BAREBOX_VERSION_EXTENSION BAREBOX_ENV BAREBOX_CONFIG_FRAGMENTS BAREBOX_BASE_BIN"

do_prepare_build[cleandirs] += "${S}/debian"
do_prepare_build() {
    deb_debianize

    if [ -n "${BAREBOX_CONFIG_FRAGMENTS}" ]; then
        (cd ${WORKDIR} && cp ${BAREBOX_CONFIG_FRAGMENTS} ${S}/)
    fi
    if [ -n "${BAREBOX_ENV}" ]; then
        (cd ${WORKDIR} && cp -r ${BAREBOX_ENV} ${S}/)
    fi
}

BAREBOX_BASE_BIN ?= "barebox"

do_deploy[dirs] = "${DEPLOY_DIR_IMAGE}"
do_deploy() {
    dpkg --fsys-tarfile ${WORKDIR}/${PN}_${CHANGELOG_V}_${DISTRO_ARCH}.deb | \
        tar xOf - ./usr/lib/barebox/barebox.bin \
        > "${DEPLOY_DIR_IMAGE}/${BAREBOX_BASE_BIN}.img"
    ln -sf ${BAREBOX_BASE_BIN}.img ${DEPLOY_DIR_IMAGE}/barebox.bin

    dpkg --fsys-tarfile ${WORKDIR}/${PN}_${CHANGELOG_V}_${DISTRO_ARCH}.deb | \
        tar xOf - ./usr/lib/barebox/barebox.config \
        > "${DEPLOY_DIR_IMAGE}/${BAREBOX_BASE_BIN}.config"
    ln -sf ${BAREBOX_BASE_BIN}.config ${DEPLOY_DIR_IMAGE}/barebox.config
}
addtask deploy before do_deploy_deb after do_dpkg_build
