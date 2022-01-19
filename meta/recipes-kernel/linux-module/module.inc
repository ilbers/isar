# Custom kernel module recipe include
#
# This software is a part of ISAR.
# Copyright (c) Siemens AG, 2018
#
# SPDX-License-Identifier: MIT

FILESEXTRAPATHS_prepend := "${FILE_DIRNAME}/files:"

DESCRIPTION ?= "Custom kernel module ${PN}"

KERNEL_NAME ?= ""

PN .= "-${KERNEL_NAME}"

KERNEL_IMAGE_PKG ??= "linux-image-${KERNEL_NAME}"
KERNEL_HEADERS_PKG ??= "linux-headers-${KERNEL_NAME}"
DEPENDS += "${KERNEL_HEADERS_PKG}"

SRC_URI += "file://debian/"

AUTOLOAD ?= ""

inherit dpkg

TEMPLATE_FILES = "debian/control.tmpl \
                  debian/changelog.tmpl"
TEMPLATE_VARS += "KERNEL_IMAGE_PKG KERNEL_HEADERS_PKG"

do_prepare_build() {
    cp -r ${WORKDIR}/debian ${S}/

    for module in "${AUTOLOAD}"; do
        echo "echo $module >> /etc/modules" >> ${S}/debian/postinst
    done
}

dpkg_runbuild_prepend() {
    # Custom kernels contain the build folder directly.
    export KDIR=$(dpkg -L --root=${BUILDCHROOT_DIR} ${KERNEL_HEADERS_PKG} | \
                  grep "/lib/modules/.*/build")
    if [ -z "$KDIR" ]; then
        # Debian kernels install that folder indirectly via a dependency.
        KERNEL_DEP=$(dpkg-query -W -f '${Depends}' --admindir=${BUILDCHROOT_DIR}/var/lib/dpkg \
                     ${KERNEL_HEADERS_PKG} | sed 's/.*\(linux-headers-[[:graph:]]*\).*/\1/')
        export KDIR=$(dpkg -L --root=${BUILDCHROOT_DIR} ${KERNEL_DEP} | \
                      grep "/lib/modules/.*/build")
    fi
    export PN=${PN}
}
