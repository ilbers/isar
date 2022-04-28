# UBI with UBIFS image recipe
#
# This software is a part of ISAR.
# Copyright (C) Siemens AG, 2019
#
# SPDX-License-Identifier: MIT

IMAGE_TYPEDEP_ubi_ubifs = "ubi"
IMAGE_TYPEDEP_ubi += "ubifs fit"

IMAGE_CMD_ubi_ubifs() {
    # we need to produce output (with extension .ubi-ubifs),
    # so just create a symlink
    ln -sf ${IMAGE_FULLNAME}.ubi ${DEPLOY_DIR_IMAGE}/${IMAGE_FULLNAME}.ubi-ubifs
}
