#
# Copyright (c) Siemens AG, 2023
#
# Authors:
#  Su Bao Cheng <baocheng.su@siemens.com>
#
# SPDX-License-Identifier: MIT
#

inherit initramfs

INITRAMFS_INSTALL += " \
    initramfs-tee-supplicant-hook \
    initramfs-tee-ftpm-hook \
    "
