# This software is a part of ISAR.
# Copyright (C) 2015-2017 ilbers GmbH

IMAGER_INSTALL_ext4 += "e2fsprogs"

MKE2FS_ARGS ?=  "-t ext4"

# Generate ext4 filesystem image
IMAGE_CMD_ext4() {
    truncate -s ${ROOTFS_SIZE}K '${IMAGE_FILE_HOST}'

    ${SUDO_CHROOT} /sbin/mke2fs ${MKE2FS_ARGS} \
                -F -d '${PP_ROOTFS}' '${IMAGE_FILE_CHROOT}'
}
#IMAGE_CMD_ext4[vardepsexclude] = "ROOTFS_SIZE ROOTFS_EXTRA"
