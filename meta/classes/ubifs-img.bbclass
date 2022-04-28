# This software is a part of ISAR.
# Copyright (C) Siemens AG, 2019
#
# SPDX-License-Identifier: MIT

IMAGER_INSTALL_ubifs += "mtd-utils"

# glibc bug 23960 https://sourceware.org/bugzilla/show_bug.cgi?id=23960
# should not use QEMU on armhf target with mkfs.ubifs < v2.1.3
THIS_ISAR_CROSS_COMPILE := "${ISAR_CROSS_COMPILE}"
ISAR_CROSS_COMPILE_armhf = "${@bb.utils.contains('IMAGE_BASETYPES', 'ubifs', '1', '${THIS_ISAR_CROSS_COMPILE}', d)}"

# Generate ubifs filesystem image
IMAGE_CMD_ubifs() {
    # Create ubifs image using buildchroot tools
    ${SUDO_CHROOT} /usr/sbin/mkfs.ubifs ${MKUBIFS_ARGS} \
                -r '${PP_ROOTFS}' '${IMAGE_FILE_CHROOT}'
}
IMAGE_CMD_REQUIRED_ARGS_ubifs = "MKUBIFS_ARGS"
