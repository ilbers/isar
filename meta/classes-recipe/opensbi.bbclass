# Custom OpenSBI build
#
# This software is a part of ISAR.
# Copyright (c) Siemens AG, 2025
#
# SPDX-License-Identifier: MIT

inherit dpkg

DESCRIPTION ?= "Custom OpenSBI"

FILESPATH:append = ":${LAYERDIR_core}/recipes-bsp/opensbi"
SRC_URI += "file://rules.tmpl"

OPENSBI_PLATFORM ?= "generic"
OPENSBI_EXTRA_BUILDARGS ?= ""

TEMPLATE_FILES = "rules.tmpl"
TEMPLATE_VARS += "OPENSBI_PLATFORM OPENSBI_EXTRA_BUILDARGS"

do_prepare_build[cleandirs] += "${S}/debian"
do_prepare_build() {
    deb_debianize

    for bin in ${OPENSBI_BIN}; do
        echo "build/platform/${OPENSBI_PLATFORM}/firmware/$bin /usr/lib/opensbi/${MACHINE}/" >> ${S}/debian/install
    done
}
