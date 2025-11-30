# Transitional include for linux-kselftest.bbclass
#
# This software is a part of ISAR.
# Copyright (c) Siemens AG, 2025
#
# SPDX-License-Identifier: MIT

inherit linux-kselftest

do_warn_custom_inc() {
    bbwarn "Please migrate from \"require recipes-kernel/kselftest/kselftest.inc\" to \"inherit linux-kselftest\""
}
addtask warn_custom_inc before do_unpack
