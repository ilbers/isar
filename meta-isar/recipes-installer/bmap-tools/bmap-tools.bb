# This software is a part of Isar.
# Copyright (c) Siemens AG, 2025
#
# SPDX-License-Identifier: MIT

inherit dpkg

MAINTAINER = "isar-users <isar-users@googlegroups.com>"

SRC_URI = "apt://${BPN}"
PN = "bmap-tools"
CHANGELOG_V="<orig-version>+isar"
DPKG_ARCH = "all"

SRC_URI += "file://0001-Fix-path-parameter-passing-error-of-set_psplash_pipe.patch;apply=no \
            file://0002-Fix-_psplash_pipe-part-was-skipped-when-_progress_fi.patch;apply=no"

do_prepare_build:append() {
    deb_add_changelog

    cd ${S}
    quilt import -f ${WORKDIR}/*.patch
    quilt push -a
}
