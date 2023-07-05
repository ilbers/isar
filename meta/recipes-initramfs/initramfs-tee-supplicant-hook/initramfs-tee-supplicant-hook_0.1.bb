# Copyright (c) Siemens AG, 2023
#
# Authors:
#  Su Bao Cheng <baocheng.su@siemens.com>
#
# SPDX-License-Identifier: MIT
#

inherit dpkg-raw

SRC_URI += " \
    file://tee-supplicant.hook \
    file://tee-supplicant.script \
    "

DEBIAN_DEPENDS = "initramfs-tools, tee-supplicant, procps"

do_install[cleandirs] += " \
    ${D}/usr/share/initramfs-tools/hooks \
    ${D}/usr/share/initramfs-tools/scripts/local-bottom"

do_install() {
    install -m 0755 "${WORKDIR}/tee-supplicant.hook" \
        "${D}/usr/share/initramfs-tools/hooks/tee-supplicant"
    install -m 0755 "${WORKDIR}/tee-supplicant.script" \
        "${D}/usr/share/initramfs-tools/scripts/local-bottom/tee-supplicant"
}
