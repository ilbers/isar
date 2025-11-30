# Transitional include for barebox.bbclass
#
# This software is a part of ISAR.
# Copyright (c) Siemens AG, 2025
#
# SPDX-License-Identifier: MIT

inherit barebox

do_warn_custom_inc() {
    bbwarn "Please migrate from \"require recipes-bsp/barebox/barebox.inc\" to \"inherit barebox\""
}
addtask warn_custom_inc before do_unpack
