# This software is a part of ISAR.
# Copyright (C) 2020 Siemens AG
#
# SPDX-License-Identifier: MIT

CPIOGZ_FNAME ?= "${IMAGE_FULLNAME}.cpio.gz"
CPIOGZ_IMAGE_FILE = "${DEPLOY_DIR_IMAGE}/${CPIOGZ_FNAME}"
IMAGER_INSTALL += "cpio"
CPIO_IMAGE_FORMAT ?= "newc"

do_cpiogz_image() {
    sudo rm -f ${CPIOGZ_IMAGE_FILE}
    image_do_mounts
    sudo chroot ${BUILDCHROOT_DIR} \
                sh -c "cd ${PP_ROOTFS}; /usr/bin/find . | \
                       /usr/bin/cpio -H ${CPIO_IMAGE_FORMAT} -o | /usr/bin/gzip -9 > \
                       ${PP_DEPLOY}/${CPIOGZ_FNAME}"
    sudo chown $(id -u):$(id -g) ${CPIOGZ_IMAGE_FILE}
}

addtask cpiogz_image before do_image after do_image_tools
