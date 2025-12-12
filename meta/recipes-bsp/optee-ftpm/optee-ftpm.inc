# Transitional include for optee-ftpm.bbclass
#
# This software is a part of ISAR.
# Copyright (c) Siemens AG, 2025
#
# SPDX-License-Identifier: MIT

inherit optee-ftpm

do_warn_custom_inc() {
    bbwarn "Please migrate from \"require recipes-bsp/optee-ftpm/optee-ftpm.inc\" to \"inherit optee-ftpm\""
}
addtask warn_custom_inc before do_unpack
