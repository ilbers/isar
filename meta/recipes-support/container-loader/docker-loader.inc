# Transitional include for docker-loader.bbclass
#
# This software is a part of ISAR.
# Copyright (c) Siemens AG, 2025
#
# SPDX-License-Identifier: MIT

inherit docker-loader

do_warn_custom_inc() {
    bbwarn "Please migrate from \"require recipes-support/container-loader/docker-loader.inc\" to \"inherit docker-loader\""
}
addtask warn_custom_inc before do_unpack
