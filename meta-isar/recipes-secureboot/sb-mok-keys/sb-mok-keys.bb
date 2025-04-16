# Base image recipe for ISAR
#
# This software is a part of ISAR.
# Copyright (C) 2022 Siemens AG

inherit dpkg

PROVIDES = "secure-boot-secrets"
DEBIAN_PROVIDES = "secure-boot-secrets"

SRC_URI = "file://Makefile.tmpl"
S = "${WORKDIR}/src"

TEMPLATE_VARS = "COMMON_NAME"
TEMPLATE_FILES = "Makefile.tmpl"

DEBIAN_BUILD_DEPENDS .= ",openssl"
# common name of x509 certificate used for signing
COMMON_NAME = "ISAR Builder"

do_prepare_build[cleandirs] += "${S}/debian"
do_prepare_build() {
    cp ${WORKDIR}/Makefile ${S}
    deb_debianize
}
