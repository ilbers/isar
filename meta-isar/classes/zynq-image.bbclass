# Create an image that can by written onto a SD card using dd
#
# Copyright (C) 2015-2016 ilbers GmbH
#
# The disk layout used is:
#
#    0K -         8K  Reserved
#    8K -        32K  Reserved
#   32K -      2048K  Reserved
# 2048K - BOOT_SPACE  Boot loader and kernel

# This image depends on the rootfs image
IMAGE_TYPEDEP_zynq-sdimg = "${SDIMG_ROOTFS_TYPE}"

# Boot partition volume id
BOOTDD_VOLUME_ID ?= "${MACHINE}"

# Boot partition size [in KiB]
BOOT_SPACE ?= "20480"

# First partition begin at sector 2048 : 2048*1024 = 2097152
IMAGE_ROOTFS_ALIGNMENT = "2048"

# Use an uncompressed ext4 by default as rootfs
SDIMG_ROOTFS_TYPE ?= "ext4"
SDIMG_ROOTFS = "${TMPDIR}/work/core-image-base-1.0-r0/deb_rootfs.ext4"
PKG_DIR = "${DEPLOY_DIR}/packages/"
ROOTFS_DIR = "${TMPDIR}/work/core-image-base-1.0-r0/rootfs"

# SD card image name
SDIMG = "${DEPLOY_DIR_IMAGE}/core-image-base-zynq.sdimg"

IMAGEDATESTAMP = "${@time.strftime('%Y.%m.%d',time.gmtime())}"

do_image () {
    # Align partitions
    BOOT_SPACE_ALIGNED=$(expr ${BOOT_SPACE} + ${IMAGE_ROOTFS_ALIGNMENT} - 1)
    BOOT_SPACE_ALIGNED=$(expr ${BOOT_SPACE_ALIGNED} - \
        ${BOOT_SPACE_ALIGNED} % ${IMAGE_ROOTFS_ALIGNMENT})
    SDIMG_SIZE=$(expr ${IMAGE_ROOTFS_ALIGNMENT} + ${BOOT_SPACE_ALIGNED} + \
        900000 + ${IMAGE_ROOTFS_ALIGNMENT})

    mkdir -p ${DEPLOY_DIR_IMAGE}
    # Initialize sdcard image file
    dd if=/dev/zero of=${SDIMG} bs=1 count=0 seek=$(expr 1024 \* ${SDIMG_SIZE})

    # Create partition table
    /sbin/parted -s ${SDIMG} mklabel msdos
    # Create boot partition and mark it as bootable
    /sbin/parted -s ${SDIMG} unit KiB mkpart primary fat32 \
        ${IMAGE_ROOTFS_ALIGNMENT} $(expr ${BOOT_SPACE_ALIGNED} \+ \
        ${IMAGE_ROOTFS_ALIGNMENT})
    /sbin/parted -s ${SDIMG} set 1 boot on
    # Create rootfs partition
    /sbin/parted -s ${SDIMG} unit KiB mkpart primary ext4 \
        $(expr ${BOOT_SPACE_ALIGNED} \+ ${IMAGE_ROOTFS_ALIGNMENT}) \
        $(expr ${BOOT_SPACE_ALIGNED} \+ ${IMAGE_ROOTFS_ALIGNMENT} \+ 900000)
    sudo parted ${SDIMG} print

    # Create a vfat image with boot files
    BOOT_BLOCKS=$(LC_ALL=C sudo parted -s ${SDIMG} unit b print \
        |awk '/ 1 / { print substr($4, 1, length($4 -1)) / 512 /2 }')
    rm -f ${WORKDIR}/boot.img
    /sbin/mkfs.vfat -n "${BOOTDD_VOLUME_ID}" -S 512 -C ${WORKDIR}/boot.img \
        $BOOT_BLOCKS

    # Burn Partitions
    # If SDIMG_ROOTFS_TYPE is a .xz file use xzcat
    if echo "${SDIMG_ROOTFS_TYPE}" | egrep -q "*\.xz"; then
        xzcat ${SDIMG_ROOTFS} | dd of=${SDIMG} conv=notrunc seek=1 bs=$(expr 1024 \* ${BOOT_SPACE_ALIGNED} + ${IMAGE_ROOTFS_ALIGNMENT} \* 1024) && sync && sync
    else
        dd if=${SDIMG_ROOTFS} of=${SDIMG} conv=notrunc seek=1 \
            bs=$(expr 1024 \* ${BOOT_SPACE_ALIGNED} + \
            ${IMAGE_ROOTFS_ALIGNMENT} \* 1024) && sync && sync
    fi
}
