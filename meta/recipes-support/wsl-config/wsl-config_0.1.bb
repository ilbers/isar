# This software is a part of Isar.
# Copyright (C) Siemens AG, 2026
#
# SPDX-License-Identifier: MIT

inherit dpkg-raw

DESCRIPTION = "WSL configuration files"
MAINTAINER = "isar-users <isar-users@googlegroups.com>"

PROVIDES := "${BPN}"
DEBIAN_PROVIDES := "${BPN}"
PN .= "-${MACHINE}"

WSL_DEFAULT_USER ?= "root"
WSL_DEFAULT_UID ?= "0"
WSL_DEFAULT_NAME ?= "${DISTRO}-${MACHINE}"

SRC_URI = " \
    file://oobe.sh \
    file://wsl.conf.tmpl \
    file://wsl-distribution.conf.tmpl \
    "

TEMPLATE_FILES = " \
    wsl.conf.tmpl \
    wsl-distribution.conf.tmpl \
    "

TEMPLATE_VARS += " \
    WSL_DEFAULT_USER \
    WSL_DEFAULT_UID \
    WSL_DEFAULT_NAME \
    "

do_install[cleandirs] += " \
    ${D}/etc \
    ${D}/usr/libexec/wsl \
    "

do_install() {
    install -m 0644 "${WORKDIR}/wsl.conf" "${D}/etc"
    install -m 0644 "${WORKDIR}/wsl-distribution.conf" "${D}/etc"
    install -m 0755 "${WORKDIR}/oobe.sh" "${D}/usr/libexec/wsl"
}
