# Transitional include for podman-loader.bbclass
#
# This software is a part of ISAR.
# Copyright (c) Siemens AG, 2025
#
# SPDX-License-Identifier: MIT

inherit podman-loader

do_warn_custom_inc() {
    bbwarn "Please migrate from \"require recipes-support/container-loader/podman-loader.inc\" to \"inherit podman-loader\""
}
addtask warn_custom_inc before do_unpack
