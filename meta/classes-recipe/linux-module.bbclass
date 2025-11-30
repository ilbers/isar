# Custom kernel module recipe include
#
# This software is a part of ISAR.
# Copyright (c) Siemens AG, 2018
#
# SPDX-License-Identifier: MIT

DESCRIPTION ?= "Custom kernel module ${PN}"
MAINTAINER ?= "isar-users <isar-users@googlegroups.com>"

KERNEL_NAME ?= ""
# directory with KBuild file (M=${MODULE_DIR})
MODULE_DIR ?= "$(PWD)"

PN .= "-${KERNEL_NAME}"

KERNEL_IMAGE_PKG ??= "linux-image-${KERNEL_NAME}"
KERNEL_HEADERS_PKG ??= "linux-headers-${KERNEL_NAME}"
DEPENDS += "${KERNEL_HEADERS_PKG}-native"
DEBIAN_BUILD_DEPENDS = "${KERNEL_HEADERS_PKG}"
# Do not generate debug symbols packages, as not supported for modules
DEB_BUILD_OPTIONS += "noautodbgsym"

SIGNATURE_KEYFILE ??= "/usr/share/secure-boot-secrets/secure-boot.key"
SIGNATURE_CERTFILE ??= "/usr/share/secure-boot-secrets/secure-boot.pem"
SIGNATURE_HASHFN ??= "sha256"
SIGNATURE_SIGNWITH ??= "/usr/bin/sign-module.sh"

KERNEL_MODULE_SIGNATURES ??= ""

# Define signing profile and dependencies if KERNEL_MODULE_SIGNATURES is set to "1"
DEB_BUILD_PROFILES += "${@'pkg.signwith' if bb.utils.to_boolean(d.getVar('KERNEL_MODULE_SIGNATURES')) else ''}"
DEPENDS += "${@'module-signer secure-boot-secrets' if bb.utils.to_boolean(d.getVar('KERNEL_MODULE_SIGNATURES')) else ''}"
DEBIAN_BUILD_DEPENDS .= "${@', module-signer, secure-boot-secrets' if bb.utils.to_boolean(d.getVar('KERNEL_MODULE_SIGNATURES')) else ''}"

FILESPATH:append = ":${LAYERDIR_core}/recipes-kernel/linux-module/files"
SRC_URI += "file://debian/"

AUTOLOAD ?= ""

# Cross-compilation is not supported for the default Debian kernels.
# For example, package with kernel headers for ARM:
#   linux-headers-armmp
# has hard dependencies from linux-compiler-gcc-4.8-arm, what
# conflicts with the host binaries.
python() {
    if d.getVar('KERNEL_NAME') in d.getVar('DISTRO_KERNELS').split():
        d.setVar('ISAR_CROSS_COMPILE', '0')
}

inherit dpkg
inherit per-kernel

TEMPLATE_FILES = "debian/control.tmpl \
                  debian/rules.tmpl"
TEMPLATE_VARS += " \
    KERNEL_NAME \
    KERNEL_TYPE \
    KERNEL_IMAGE_PKG \
    KERNEL_HEADERS_PKG \
    KCFLAGS \
    KAFLAGS \
    MODULE_DIR \
    DEBIAN_BUILD_DEPENDS \
    SIGNATURE_KEYFILE \
    SIGNATURE_CERTFILE \
    SIGNATURE_HASHFN \
    SIGNATURE_SIGNWITH \
    PN \
    DEBIAN_COMPAT \
    DEBIAN_STANDARDS_VERSION"

# Add custom cflags to the kernel build
KCFLAGS ?= "-fdebug-prefix-map=${CURDIR}=. -fmacro-prefix-map=${CURDIR}=."
KAFLAGS ?= "-fdebug-prefix-map=${CURDIR}=."

do_prepare_build() {
    rm -rf ${S}/debian
    cp -r ${WORKDIR}/debian ${S}/

    deb_add_changelog

    for module in ${AUTOLOAD}; do
        echo "echo $module >> /etc/modules" >> ${S}/debian/postinst
    done
}
