# This software is a part of ISAR.
# Copyright (C) Siemens AG, 2019-2025
#
# SPDX-License-Identifier: MIT

DESCRIPTION = "Recipe to add fsck hook to the initramfs"

inherit initramfs-hook

SRC_URI += "file://initramfs-fsck-hook-ext4.triggers"

HOOK_COPY_EXECS = "fsck fsck.ext4 logsave"

DEBIAN_DEPENDS .= ", e2fsprogs, logsave"
