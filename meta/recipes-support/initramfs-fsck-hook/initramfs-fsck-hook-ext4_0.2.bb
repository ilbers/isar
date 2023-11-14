# This software is a part of ISAR.
# Copyright (C) Siemens AG, 2019
#
# SPDX-License-Identifier: MIT


DESCRIPTION = "Recipe to add fsck hook to the initramfs"

inherit dpkg-raw
SRC_URI = "file://initramfs-fsck-hook-ext4.triggers \
           file://initramfs.fsck.ext4.hook \
          "


do_install() {
        install -m 0755 -d ${D}/etc/initramfs-tools/hooks
        install -m 0740 ${WORKDIR}/initramfs.fsck.ext4.hook ${D}/etc/initramfs-tools/hooks/fsck.ext4.hook
}
