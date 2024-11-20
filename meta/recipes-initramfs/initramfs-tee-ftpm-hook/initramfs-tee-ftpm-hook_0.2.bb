# Copyright (c) Siemens AG, 2023-2024
#
# Authors:
#  Su Bao Cheng <baocheng.su@siemens.com>
#
# SPDX-License-Identifier: MIT
#

require recipes-initramfs/initramfs-hook/hook.inc

SRC_URI += "file://local-top"

HOOK_PREREQ = "tee-supplicant"
HOOK_ADD_MODULES = "tpm_ftpm_tee"
SCRIPT_PREREQ = "tee-supplicant"
