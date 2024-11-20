# Copyright (c) Siemens AG, 2023-2024
#
# Authors:
#  Su Bao Cheng <baocheng.su@siemens.com>
#
# SPDX-License-Identifier: MIT
#

require recipes-initramfs/initramfs-hook/hook.inc

SRC_URI += "file://local-top"

HOOK_ADD_MODULES = "tee optee"
HOOK_COPY_EXECS = "tee-supplicant pgrep"

DEBIAN_DEPENDS .= ", tee-supplicant, procps"
