# Copyright (c) Siemens AG, 2023-2025
#
# Authors:
#  Su Bao Cheng <baocheng.su@siemens.com>
#
# SPDX-License-Identifier: MIT
#

require recipes-initramfs/initramfs-hook/hook.inc

SRC_URI += "file://local-top"

# Can be disabled with kernel 6.12 and above
# NOTE: default will eventually be flipped
TEE_SUPPLICANT_IN_USERLAND ?= "1"

HOOK_PREREQ = "${@'tee-supplicant' if bb.utils.to_boolean(d.getVar('TEE_SUPPLICANT_IN_USERLAND')) else ''}"
HOOK_ADD_MODULES = "tpm_ftpm_tee"
SCRIPT_PREREQ = "${@'tee-supplicant' if bb.utils.to_boolean(d.getVar('TEE_SUPPLICANT_IN_USERLAND')) else ''}"
