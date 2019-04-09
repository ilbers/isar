# This software is a part of ISAR.
# Copyright (C) Siemens AG, 2019
#
# SPDX-License-Identifier: MIT

MKIMAGE_ARGS ??= ""

FIT_IMAGE_SOURCE ??= "fitimage.its"

inherit image

FIT_IMAGE_FILE ?= "${IMAGE_FULLNAME}.fit.img"

IMAGER_INSTALL += "u-boot-tools device-tree-compiler"

# Generate fit image
do_fit_image() {
    if [ ! -e "${WORKDIR}/${FIT_IMAGE_SOURCE}" ]; then
        die "FIT_IMAGE_SOURCE does not contain fitimage source file"
    fi

    rm -f '${DEPLOY_DIR_IMAGE}/${FIT_IMAGE_FILE}'

    image_do_mounts

    # Create fit image using buildchroot tools
    sudo chroot ${BUILDCHROOT_DIR} /usr/bin/mkimage ${MKIMAGE_ARGS} \
                -f '${PP_WORK}/${FIT_IMAGE_SOURCE}' '${PP_DEPLOY}/${FIT_IMAGE_FILE}'
}
addtask fit_image before do_build after do_copy_boot_files do_install_imager_deps do_unpack do_transform_template
