# Transitional include for trusted-firmware-a.bbclass
#
# This software is a part of ISAR.
# Copyright (c) Siemens AG, 2025
#
# SPDX-License-Identifier: MIT

inherit trusted-firmware-a

do_warn_custom_inc() {
    bbwarn "Please migrate from \"require recipes-bsp/trusted-firmware-a/trusted-firmware-a-custom.inc\" to \"inherit trusted-firmware-a\""
}
addtask warn_custom_inc before do_unpack
