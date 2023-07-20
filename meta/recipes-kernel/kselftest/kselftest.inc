# Kselftest package for Linux
#
# This software is a part of ISAR.
# Copyright (c) Mentor Graphics, a Siemens Business, 2020
#
# SPDX-License-Identifier: MIT

inherit dpkg

FILESEXTRAPATHS:prepend := "${THISDIR}/files:"

# Some test-cases like memfd compilation failed in cross-compilation.
# Force native compilation for now to have consistent output across
# ISAR native/cross compilation setups.
ISAR_CROSS_COMPILE = "0"

DESCRIPTION ?= "Kernel selftests from Linux kernel ${PV}"

DEBIAN_BUILD_DEPENDS ?= " \
    rsync, \
    flex,  \
    bison, \
    ${@ 'fuse3' if d.getVar('BASE_DISTRO_CODENAME') == 'bookworm' else 'fuse'}, \
    libelf-dev:native, \
    libcap-ng-dev:native, \
    libpopt-dev:native, \
    libcap-dev:native, \
    libmount-dev:native, \
    libfuse-dev:native, \
    libmnl-dev:native, \
    pkg-config, \
    clang:native, \
    llvm:native, \
"

SRC_URI += "file://rules.tmpl"
S = "${WORKDIR}/linux-${PV}"

TEMPLATE_FILES = "rules.tmpl"
TEMPLATE_VARS += "KSELFTEST_ARGS"

KSELFTEST_TARGETS ?= ""
KSELFTEST_SKIP_TARGETS ?= ""
KSELFTEST_FORCE_TARGETS ?= "0"

KSELFTEST_ARGS = "${@ "TARGETS=\"${KSELFTEST_TARGETS}\"" if d.getVar('KSELFTEST_TARGETS') else ''}"
KSELFTEST_ARGS .= "${@ " FORCE_TARGETS=1" if d.getVar('KSELFTEST_FORCE_TARGETS') == '1' else ''}"
KSELFTEST_ARGS .= "${@ " SKIP_TARGETS=\"${KSELFTEST_SKIP_TARGETS}\"" if d.getVar('KSELFTEST_SKIP_TARGETS') else ''}"

do_prepare_build[cleandirs] += "${S}/debian"
do_prepare_build() {
    deb_debianize
}
