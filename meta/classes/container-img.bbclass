# This software is a part of ISAR.
# Copyright (C) Siemens AG, 2021
#
# SPDX-License-Identifier: MIT
#
# This class provides the task 'containerize_rootfs'
# to create container images containing the target rootfs.

do_container_image[stamp-extra-info] = "${DISTRO}-${MACHINE}"
do_container_image[vardeps] += "CONTAINER_FORMATS"
do_container_image(){
    rootfs_id="${DISTRO}-${DISTRO_ARCH}"

    bbdebug 1 "Generate container image in these formats: ${CONTAINER_FORMATS}"
    containerize_rootfs "${IMAGE_ROOTFS}" "${rootfs_id}" "${CONTAINER_FORMATS}"
}

addtask container_image before do_image after do_image_tools
