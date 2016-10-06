# This software is a part of ISAR.
# Copyright (C) 2015-2016 ilbers GmbH

# Extra space for rootfs in MB
ROOTFS_EXTRA ?= "64"

# Generate ext4 filesystem image
do_ext4_image() {
    mkdir -p ${DEPLOY_DIR_IMAGE}

    rm -f ${DEPLOY_DIR_IMAGE}/${PN}.ext4.img

    ROOTFS_SIZE=`sudo du -sm ${S} |  awk '{print $1 + ${ROOTFS_EXTRA};}'`
    dd if=/dev/zero of=${DEPLOY_DIR_IMAGE}/${PN}.ext4.img bs=1M count=${ROOTFS_SIZE}

    sudo mkfs.ext4 -F ${DEPLOY_DIR_IMAGE}/${PN}.ext4.img

    mkdir -p ${WORKDIR}/mnt
    sudo mount -o loop ${DEPLOY_DIR_IMAGE}/${PN}.ext4.img ${WORKDIR}/mnt
    sudo cp -r ${S}/* ${WORKDIR}/mnt
    sudo umount ${WORKDIR}/mnt
    rm -r ${WORKDIR}/mnt

    if [ -n "${KERNEL_IMAGE}" ]; then
        cp ${S}/boot/${KERNEL_IMAGE} ${DEPLOY_DIR_IMAGE}
    fi

    if [ -n "${INITRD_IMAGE}" ]; then
        cp ${S}/boot/${INITRD_IMAGE} ${DEPLOY_DIR_IMAGE}
    fi
}

addtask ext4_image before do_build after do_populate
