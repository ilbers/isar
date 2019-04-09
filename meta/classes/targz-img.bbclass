# This software is a part of ISAR.
# Copyright (c) Siemens AG, 2018
#
# SPDX-License-Identifier: MIT

TARGZ_IMAGE_FILE = "${DEPLOY_DIR_IMAGE}/${IMAGE_FULLNAME}.tar.gz"

do_targz_image[stamp-extra-info] = "${DISTRO}-${MACHINE}"

do_targz_image() {
    rm -f ${TARGZ_IMAGE_FILE}
    sudo tar -cvzf ${TARGZ_IMAGE_FILE} --one-file-system -C ${IMAGE_ROOTFS} .
}

addtask targz_image before do_build after do_mark_rootfs
