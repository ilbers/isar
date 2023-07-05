# Copyright (c) Siemens AG, 2023
#
# Authors:
#  Su Bao Cheng <baocheng.su@siemens.com>
#
# SPDX-License-Identifier: MIT
#

inherit dpkg-raw

SRC_URI += " \
    file://tee-ftpm.hook \
    file://tee-ftpm.script \
    "

DEBIAN_DEPENDS = "initramfs-tools"

do_install[cleandirs] += " \
    ${D}/usr/share/initramfs-tools/hooks \
    ${D}/usr/share/initramfs-tools/scripts/local-bottom"

do_install() {
    install -m 0755 "${WORKDIR}/tee-ftpm.hook" \
        "${D}/usr/share/initramfs-tools/hooks/tee-ftpm"
    install -m 0755 "${WORKDIR}/tee-ftpm.script" \
        "${D}/usr/share/initramfs-tools/scripts/local-bottom/tee-ftpm"
}
