# Base image recipe for Isar
#
# This software is a part of Isar.
# Copyright (C) 2022 Siemens AG

inherit dpkg

MAINTAINER = "isar-users <isar-users@googlegroups.com>"

PROVIDES = "secure-boot-secrets"
DEBIAN_PROVIDES = "secure-boot-secrets"

SRC_URI = "file://Makefile.tmpl"
S = "${WORKDIR}/src"

TEMPLATE_VARS = "COMMON_NAME"
TEMPLATE_FILES = "Makefile.tmpl"

DEBIAN_BUILD_DEPENDS .= ",openssl"
# common name of x509 certificate used for signing
COMMON_NAME = "Isar Builder"

do_prepare_build[cleandirs] += "${S}/debian"
do_prepare_build() {
    cp ${WORKDIR}/Makefile ${S}
    deb_debianize
}
