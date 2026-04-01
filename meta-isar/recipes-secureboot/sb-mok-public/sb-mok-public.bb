# Base image recipe for Isar
#
# This software is a part of Isar.
# Copyright (C) 2022 Siemens AG

inherit dpkg

DEPENDS += "sb-mok-keys"
DEBIAN_BUILD_DEPENDS .= ",sb-mok-keys"
DEBIAN_CONFLICTS .= ",sb-mok-keys"

SRC_URI = "file://rules"

do_prepare_build[cleandirs] += "${S}/debian"
do_prepare_build() {
    deb_debianize
}
