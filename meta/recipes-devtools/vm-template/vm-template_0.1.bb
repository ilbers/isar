# This software is a part of ISAR.
#
# Copyright (c) Siemens AG, 2020
#
# SPDX-License-Identifier: MIT

inherit dpkg-raw

SRC_URI += "file://vm-template.ovf.tmpl"

do_install() {
    TARGET=${D}/usr/share/vm-template
    install -m 0755 -d ${TARGET}
    install -m 0740 ${WORKDIR}/vm-template.ovf.tmpl \
        ${TARGET}/vm-template.ovf.tmpl
}
