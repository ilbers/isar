# Distro kernel dummy package
#
# This software is a part of Isar.
# Copyright (c) Siemens AG, 2018
# Copyright (C) 2022-2026 ilbers GmbH
#
# SPDX-License-Identifier: MIT

python() {
    overrides = d.getVar("OVERRIDES").split(":")
    if any(o in overrides for o in ("class-native", "class-compat")):
        return

    distro_kernels = d.getVar('DISTRO_KERNELS') or ""
    kernel_img_pkg = d.getVar('KERNEL_IMAGE_PKG')
    kernel_headers_pkg = d.getVar('KERNEL_HEADERS_PKG')

    for kernel in distro_kernels.split():
        for prefix in ['linux-image', 'linux-headers', 'linux-kbuild']:
            d.appendVar('PROVIDES', ' {}-{}'.format(prefix, kernel))
            d.appendVar('RPROVIDES', ' {}-{}'.format(prefix, kernel))
    if kernel_img_pkg:
        d.appendVar('PROVIDES', ' ' + kernel_img_pkg)
        d.appendVar('RPROVIDES', ' ' + kernel_img_pkg)
    if kernel_headers_pkg:
        d.appendVar('PROVIDES', ' ' + kernel_headers_pkg)
        d.appendVar('RPROVIDES', ' ' + kernel_headers_pkg)
}

inherit multiarch
inherit dpkg
inherit linux-deploy

# Always use target arch for kernel package lookup
ISAR_CROSS_COMPILE = "0"

MAINTAINER = "isar-users <isar-users@googlegroups.com>"

PN .= "-${KERNEL_NAME}"
KERNEL_NAME_PROVIDED ??= "${KERNEL_NAME}"
DEBIAN_BUILD_DEPENDS ?= "${@d.getVar('KERNEL_IMAGE_PKG') or ('linux-image-' + (d.getVar('KERNEL_NAME') or ''))}"

FILESPATH:prepend = "${LAYERDIR_core}/recipes-kernel/linux/files:"

SRC_URI = "file://getkernel.sh \
           file://rules.tmpl"

TEMPLATE_VARS += "KERNEL_FILE KERNEL_DEB"
TEMPLATE_FILES = "rules.tmpl"

do_prepare_build[cleandirs] += "${S}/debian"
do_prepare_build() {
    deb_debianize
    cp "${WORKDIR}/getkernel.sh" "${S}/debian/"
}
do_deploy_deb[noexec] = "1"
