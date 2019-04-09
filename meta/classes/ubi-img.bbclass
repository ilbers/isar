# This software is a part of ISAR.
# Copyright (C) Siemens AG, 2019
#
# SPDX-License-Identifier: MIT

python() {
    if not d.getVar("UBINIZE_ARGS"):
        bb.fatal("UBINIZE_ARGS must be set")
}

UBINIZE_CFG ??= "ubinize.cfg"

inherit image

UBI_IMAGE_FILE ?= "${IMAGE_FULLNAME}.ubi.img"

IMAGER_INSTALL += "mtd-utils"

# Generate ubi filesystem image
do_ubi_image() {
    if [ ! -e "${WORKDIR}/${UBINIZE_CFG}" ]; then
        die "UBINIZE_CFG does not contain ubinize config file."
    fi

    rm -f '${DEPLOY_DIR_IMAGE}/${UBI_IMAGE_FILE}'

    image_do_mounts

    # Create ubi image using buildchroot tools
    sudo chroot ${BUILDCHROOT_DIR} /usr/sbin/ubinize ${UBINIZE_ARGS} \
                -o '${PP_DEPLOY}/${UBI_IMAGE_FILE}' '${PP_WORK}/${UBINIZE_CFG}'
}
addtask ubi_image before do_build after do_copy_boot_files do_install_imager_deps do_unpack do_transform_template
