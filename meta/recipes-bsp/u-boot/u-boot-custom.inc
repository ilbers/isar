# Transitional include for u-boot.bbclass
#
# This software is a part of ISAR.
# Copyright (c) Siemens AG, 2025
#
# SPDX-License-Identifier: MIT

inherit u-boot

do_warn_custom_inc() {
    bbwarn "Please migrate from \"require recipes-bsp/u-boot/u-boot-custom.inc\" to \"inherit u-boot\""
}
addtask warn_custom_inc before do_unpack
