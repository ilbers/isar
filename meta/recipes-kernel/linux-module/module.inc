# Transitional include for linux-module.bbclass
#
# This software is a part of ISAR.
# Copyright (c) Siemens AG, 2025
#
# SPDX-License-Identifier: MIT

inherit linux-module

do_warn_custom_inc() {
    bbwarn "Please migrate from \"require recipes-kernel/linux-module/module.inc\" to \"inherit linux-module\""
}
addtask warn_custom_inc before do_unpack
