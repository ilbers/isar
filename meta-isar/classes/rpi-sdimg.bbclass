# This software is a part of ISAR.
# Copyright (C) 2015-2016 ilbers GmbH
#
# Based on SD class from meta-raspberrypi

inherit ext4-img

# Boot partition volume id
BOOTDD_VOLUME_ID ?= "${MACHINE}"

# Boot partition size [in KiB]
BOOT_SPACE ?= "40960"

# Set alignment to 4MB [in KiB]
IMAGE_ROOTFS_ALIGNMENT = "4096"

SDIMG = "${DEPLOY_DIR_IMAGE}/${IMAGE_FULLNAME}.sdimg"
SDIMG_ROOTFS = "${DEPLOY_DIR_IMAGE}/${EXT4_IMAGE_FILE}"

do_rpi_sdimg () {
    # Align partitions
    ROOTFS_SIZE=$(du -b ${SDIMG_ROOTFS} | cut -f 1)
    ROOTFS_SIZE=$(expr ${ROOTFS_SIZE} + 1)
    ROOTFS_SIZE=$(expr ${ROOTFS_SIZE} - ${ROOTFS_SIZE} % 1024)
    ROOTFS_SIZE=$(expr ${ROOTFS_SIZE} / 1024)
    ROOTFS_SIZE=$(expr ${ROOTFS_SIZE} - ${ROOTFS_SIZE} % ${IMAGE_ROOTFS_ALIGNMENT} + ${IMAGE_ROOTFS_ALIGNMENT})

    BOOT_SPACE_ALIGNED=$(expr ${BOOT_SPACE} + ${IMAGE_ROOTFS_ALIGNMENT} - 1)
    BOOT_SPACE_ALIGNED=$(expr ${BOOT_SPACE_ALIGNED} - ${BOOT_SPACE_ALIGNED} % ${IMAGE_ROOTFS_ALIGNMENT})
    SDIMG_SIZE=$(expr ${IMAGE_ROOTFS_ALIGNMENT} + ${BOOT_SPACE_ALIGNED} + ${ROOTFS_SIZE})

    echo "Creating filesystem with Boot partition ${BOOT_SPACE_ALIGNED} KiB and RootFS $ROOTFS_SIZE KiB"

    #Initialize sdcard image file
    dd if=/dev/zero of=${SDIMG} bs=1024 count=0 seek=${SDIMG_SIZE}

    # Create partition table
    parted -s ${SDIMG} mklabel msdos
    # Create boot partition and mark it as bootable
    parted -s ${SDIMG} unit KiB mkpart primary fat32 ${IMAGE_ROOTFS_ALIGNMENT} $(expr ${BOOT_SPACE_ALIGNED} \+ ${IMAGE_ROOTFS_ALIGNMENT})
    parted -s ${SDIMG} set 1 boot on
    # Create rootfs partition to the end of disk
    parted -s ${SDIMG} -- unit KiB mkpart primary ext2 $(expr ${BOOT_SPACE_ALIGNED} \+ ${IMAGE_ROOTFS_ALIGNMENT}) -1s
    parted ${SDIMG} print

    # Create a vfat image with boot files
    BOOT_BLOCKS=$(LC_ALL=C parted -s ${SDIMG} unit b print | awk '/ 1 / { print substr($4, 1, length($4 -1)) / 512 /2 }')
    rm -f ${WORKDIR}/boot.img
    mkfs.vfat -n "${BOOTDD_VOLUME_ID}" -S 512 -C ${WORKDIR}/boot.img $BOOT_BLOCKS
    mcopy -i ${WORKDIR}/boot.img -s ${IMAGE_ROOTFS}/boot/* ::/

    # Burn Partitions
    dd if=${WORKDIR}/boot.img of=${SDIMG} conv=notrunc seek=1 bs=$(expr ${IMAGE_ROOTFS_ALIGNMENT} \* 1024) && sync && sync
    dd if=${SDIMG_ROOTFS} of=${SDIMG} conv=notrunc seek=1 bs=$(expr 1024 \* ${BOOT_SPACE_ALIGNED} + ${IMAGE_ROOTFS_ALIGNMENT} \* 1024) && sync && sync
}

addtask rpi_sdimg before do_build after do_ext4_image
