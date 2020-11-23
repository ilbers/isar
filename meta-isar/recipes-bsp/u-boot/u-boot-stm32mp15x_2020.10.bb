#
# Copyright (c) Siemens AG, 2020
#
# SPDX-License-Identifier: MIT

require u-boot-${PV}.inc

SRC_URI += " \
    file://0001-fdtdec-optionally-add-property-no-map-to-created-res.patch \
    file://0002-optee-add-property-no-map-to-secure-reserved-memory.patch"
