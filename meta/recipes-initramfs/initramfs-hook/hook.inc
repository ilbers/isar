# Transitional include for u-boot.bbclass
#
# This software is a part of ISAR.
# Copyright (c) Siemens AG, 2025
#
# SPDX-License-Identifier: MIT

inherit initramfs-hook

do_warn_custom_inc() {
    bbwarn "Please migrate from \"require recipes-initramfs/initramfs-hook/hook.inc\" to \"inherit initramfs-hook\""
}
addtask warn_custom_inc before do_unpack
