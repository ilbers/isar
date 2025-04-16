# Example recipe for signing a kernel module with custom signer script
#
# This software is a part of ISAR.
# Copyright (c) Siemens AG, 2025
#
# SPDX-License-Identifier: MIT

inherit dpkg-raw

DPKG_ARCH = "all"

PROVIDES = "module-signer"
DEBIAN_PROVIDES = "module-signer"

DEPENDS = "sb-mok-keys"
DEBIAN_DEPENDS += "openssl, sb-mok-keys"

SRC_URI = "file://sign-module.sh"

do_install[cleandirs] = "${D}/usr/bin/"
do_install() {
    install -m 0755 ${WORKDIR}/sign-module.sh ${D}/usr/bin/sign-module.sh
}
