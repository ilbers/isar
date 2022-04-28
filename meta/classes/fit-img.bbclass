# This software is a part of ISAR.
# Copyright (C) Siemens AG, 2019
#
# SPDX-License-Identifier: MIT

MKIMAGE_ARGS ??= ""

FIT_IMAGE_SOURCE ??= "fitimage.its"

IMAGER_INSTALL_fit += "u-boot-tools device-tree-compiler"

# Generate fit image
IMAGE_CMD_fit() {
    if [ ! -e "${WORKDIR}/${FIT_IMAGE_SOURCE}" ]; then
        die "FIT_IMAGE_SOURCE does not contain fitimage source file"
    fi

    # Create fit image using buildchroot tools
    ${SUDO_CHROOT} /usr/bin/mkimage ${MKIMAGE_ARGS} \
                -f '${PP_WORK}/${FIT_IMAGE_SOURCE}' '${IMAGE_FILE_CHROOT}'
}
IMAGE_CMD_fit[depends] = "${PN}:do_transform_template"
