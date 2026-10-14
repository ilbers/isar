# This software is a part of Isar.
# Copyright (C) 2026 Siemens AG
#
# SPDX-License-Identifier: MIT
#
# test package built in two variants that share one source package name and
# one architecture, as the kernel recipes do via kbuildtarget.bbclass. Each
# variant produces a differently named binary package, so a cleanup that keys
# on the source package instead of the recipe is visible in isar-apt.
DPKG_ARCH = "any"
SRC_URI = "file://control"

MAINTAINER = "isar-users <isar-users@googlegroups.com>"

inherit dpkg-raw
inherit kbuildtarget

BBCLASSEXTEND = "kbuildtarget"

DEB_BUILD_PROFILES = "pkg.${BPN}.base"
DEB_BUILD_PROFILES:class-kbuildtarget = "pkg.${BPN}.extra"

do_prepare_build:append() {
    cp ${WORKDIR}/control ${S}/debian/
}
