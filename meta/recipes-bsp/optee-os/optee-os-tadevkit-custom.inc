# Transitional include for optee-os-tadevkit.bbclass
#
# This software is a part of ISAR.
# Copyright (c) Siemens AG, 2025
#
# SPDX-License-Identifier: MIT

inherit optee-os-tadevkit

do_warn_custom_inc() {
    bbwarn "Please migrate from \"require recipes-bsp/optee-os/optee-os-tadevkit-custom.inc\" to \"inherit optee-os-tadevkit\""
}
addtask warn_custom_inc before do_unpack
