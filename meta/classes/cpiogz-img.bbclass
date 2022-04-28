# This software is a part of ISAR.
# Copyright (C) 2020 Siemens AG
#
# SPDX-License-Identifier: MIT

IMAGER_INSTALL_cpio += "cpio"
CPIO_IMAGE_FORMAT ?= "newc"

IMAGE_CMD_cpio() {
    ${SUDO_CHROOT} \
        sh -c "cd ${PP_ROOTFS}; /usr/bin/find . | \
               /usr/bin/cpio -H ${CPIO_IMAGE_FORMAT} -o > \
               ${IMAGE_FILE_CHROOT}"
}
