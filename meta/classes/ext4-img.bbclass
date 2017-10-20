# This software is a part of ISAR.
# Copyright (C) 2015-2017 ilbers GmbH

# Extra space for rootfs in MB
ROOTFS_EXTRA ?= "64"

EXT4_IMAGE_FILE = "${DEPLOY_DIR_IMAGE}/${PN}-${DISTRO}-${MACHINE}.ext4.img"

do_ext4_image[stamp-extra-info] = "${DISTRO}-${MACHINE}"

# Generate ext4 filesystem image
do_ext4_image() {
    rm -f ${EXT4_IMAGE_FILE}

    ROOTFS_SIZE=`sudo du -sm ${IMAGE_ROOTFS} |  awk '{print $1 + ${ROOTFS_EXTRA};}'`
    dd if=/dev/zero of=${EXT4_IMAGE_FILE} bs=1M count=${ROOTFS_SIZE}

    sudo mkfs.ext4 -F ${EXT4_IMAGE_FILE}

    mkdir -p ${WORKDIR}/mnt
    sudo mount -o loop ${EXT4_IMAGE_FILE} ${WORKDIR}/mnt
    sudo cp -r ${IMAGE_ROOTFS}/* ${WORKDIR}/mnt
    sudo umount ${WORKDIR}/mnt
    rm -r ${WORKDIR}/mnt
}

addtask ext4_image before do_build after do_copy_boot_files
