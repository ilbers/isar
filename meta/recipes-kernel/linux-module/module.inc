# Custom kernel module recipe include
#
# This software is a part of ISAR.
# Copyright (c) Siemens AG, 2018
#
# SPDX-License-Identifier: MIT

FILESEXTRAPATHS_prepend := "${FILE_DIRNAME}/files:"

DESCRIPTION ?= "Custom kernel module ${PN}"

PN .= "-${KERNEL_NAME}"

DEPENDS += "linux-headers-${KERNEL_NAME}"

SRC_URI += "file://debian/"

AUTOLOAD ?= ""

inherit dpkg

TEMPLATE_FILES = "debian/control.tmpl \
                  debian/changelog.tmpl"
TEMPLATE_VARS += "KERNEL_NAME"

do_prepare_build() {
    cp -r ${WORKDIR}/debian ${S}/

    for module in "${AUTOLOAD}"; do
        echo "echo $module >> /etc/modules" >> ${S}/debian/postinst
    done
}

dpkg_runbuild_prepend() {
    # Custom kernels contain the build folder directly.
    export KDIR=$(dpkg -L --root=${BUILDCHROOT_DIR} linux-headers-${KERNEL_NAME} | \
                  grep "/lib/modules/.*/build")
    if [ -z "$KDIR" ]; then
        # Debian kernels install that folder indirectly via a dependency.
        KERNEL_DEP=$(dpkg -s --root=${BUILDCHROOT_DIR} linux-headers-${KERNEL_NAME} | \
                     grep "^Depends: .*linux-headers-" | \
                     sed 's/.*\(linux-headers-[^,]*\).*/\1/')
        export KDIR=$(dpkg -L --root=${BUILDCHROOT_DIR} ${KERNEL_DEP} | \
                      grep "/lib/modules/.*/build")
    fi
    export PN=${PN}
}
