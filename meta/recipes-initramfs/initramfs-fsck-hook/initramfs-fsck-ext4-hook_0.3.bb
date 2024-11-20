# This software is a part of ISAR.
# Copyright (C) Siemens AG, 2019-2024
#
# SPDX-License-Identifier: MIT

DESCRIPTION = "Recipe to add fsck hook to the initramfs"

require recipes-initramfs/initramfs-hook/hook.inc

SRC_URI += "file://initramfs-fsck-hook-ext4.triggers"

HOOK_COPY_EXECS = "fsck fsck.ext4 logsave"

DEBIAN_DEPENDS .= ", e2fsprogs, logsave"
