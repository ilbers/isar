# Transitional include for linux-kernel.bbclass
#
# This software is a part of ISAR.
# Copyright (c) Siemens AG, 2025
#
# SPDX-License-Identifier: MIT

inherit linux-kernel

do_warn_custom_inc() {
    bbwarn "Please migrate from \"require recipes-kernel/linux/linux-custom.inc\" to \"inherit linux-kernel\""
}
addtask warn_custom_inc before do_unpack
