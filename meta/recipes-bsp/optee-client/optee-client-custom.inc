# Transitional include for optee-client.bbclass
#
# Copyright (c) Siemens AG, 2025
#
# Authors:
#  Jan Kiszka <jan.kiszka@siemens.com>
#
# SPDX-License-Identifier: MIT
#

inherit optee-client

do_warn_custom_inc() {
    bbwarn "Please migrate from \"require recipes-bsp/optee-client/optee-client-custom.inc\" to \"inherit optee-client\""
}
addtask warn_custom_inc before do_unpack
