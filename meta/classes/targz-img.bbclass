# This software is a part of ISAR.
# Copyright (c) Siemens AG, 2018
#
# SPDX-License-Identifier: MIT

IMAGE_CMD_tar() {
    sudo tar -cvzf ${DEPLOY_DIR_IMAGE}/${IMAGE_FULLNAME}.tar.gz --one-file-system -C ${IMAGE_ROOTFS} .
}
