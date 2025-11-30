# Transitional include for optee-os.bbclass
#
# This software is a part of ISAR.
# Copyright (c) Siemens AG, 2025
#
# SPDX-License-Identifier: MIT

inherir optee-os

do_warn_custom_inc() {
    bbwarn "Please migrate from \"require recipes-bsp/optee-os/optee-os-custom.inc\" to \"inherit optee-os\""
}
addtask warn_custom_inc before do_unpack
