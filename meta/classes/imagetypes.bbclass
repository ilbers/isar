# This software is a part of ISAR.
# Copyright (C) 2021 Siemens AG
#
# SPDX-License-Identifier: MIT

#image type: tar
IMAGER_INSTALL:tar = "tar"
TAR_OPTIONS ?= ""

IMAGE_CMD:tar() {
    ${SUDO_CHROOT} tar ${TAR_OPTIONS} -cvSf \
                 ${IMAGE_FILE_CHROOT} --one-file-system -C ${PP_ROOTFS} .
}

# image type: ext4
IMAGER_INSTALL:ext4 += "e2fsprogs"
MKE2FS_ARGS ?=  "-t ext4"

IMAGE_CMD:ext4() {
    truncate -s ${ROOTFS_SIZE}K '${IMAGE_FILE_HOST}'

    ${SUDO_CHROOT} /sbin/mke2fs ${MKE2FS_ARGS} \
                -F -d '${PP_ROOTFS}' '${IMAGE_FILE_CHROOT}'
}

# image type: cpio
IMAGER_INSTALL:cpio += "cpio"
CPIO_IMAGE_FORMAT ?= "newc"

IMAGE_CMD:cpio() {
    ${SUDO_CHROOT} \
        sh -c "cd ${PP_ROOTFS}; /usr/bin/find . | \
               /usr/bin/cpio -H ${CPIO_IMAGE_FORMAT} -o > \
               ${IMAGE_FILE_CHROOT}"
}

# image type: fit
MKIMAGE_ARGS ??= ""
FIT_IMAGE_SOURCE ??= "fitimage.its"
IMAGER_INSTALL:fit += "u-boot-tools device-tree-compiler"

IMAGE_SRC_URI:fit = "file://${FIT_IMAGE_SOURCE}.tmpl"
IMAGE_TEMPLATE_FILES:fit = "${FIT_IMAGE_SOURCE}.tmpl"
IMAGE_TEMPLATE_VARS:fit = "KERNEL_IMG INITRD_IMG DTB_IMG"

# Default fit image deploy path (inside imager)
FIT_IMG ?= "${PP_DEPLOY}/${IMAGE_FULLNAME}.fit"

IMAGE_CMD:fit() {
    if [ ! -e "${WORKDIR}/${FIT_IMAGE_SOURCE}" ]; then
        die "FIT_IMAGE_SOURCE does not contain fitimage source file"
    fi

    ${SUDO_CHROOT} /usr/bin/mkimage ${MKIMAGE_ARGS} \
                -f '${PP_WORK}/${FIT_IMAGE_SOURCE}' '${IMAGE_FILE_CHROOT}'
}
IMAGE_CMD:fit[depends] = "${PN}:do_transform_template"

# image type: ubifs
IMAGER_INSTALL:ubifs += "mtd-utils"
IMAGE_CMD_REQUIRED_ARGS:ubifs = "MKUBIFS_ARGS"

# Default UBIFS image deploy path (inside imager)
UBIFS_IMG ?= "${PP_DEPLOY}/${IMAGE_FULLNAME}.ubifs"

# glibc bug 23960 https://sourceware.org/bugzilla/show_bug.cgi?id=23960
# should not use QEMU on armhf target with mkfs.ubifs < v2.1.3
THIS_ISAR_CROSS_COMPILE := "${ISAR_CROSS_COMPILE}"
ISAR_CROSS_COMPILE:armhf = "${@bb.utils.contains('IMAGE_BASETYPES', 'ubifs', '1', '${THIS_ISAR_CROSS_COMPILE}', d)}"

IMAGE_CMD:ubifs() {
    ${SUDO_CHROOT} /usr/sbin/mkfs.ubifs ${MKUBIFS_ARGS} \
                -r '${PP_ROOTFS}' '${IMAGE_FILE_CHROOT}'
}

# image type: ubi
IMAGER_INSTALL:ubi += "mtd-utils"
IMAGE_CMD_REQUIRED_ARGS:ubi = "UBINIZE_ARGS"
UBINIZE_CFG ??= "ubinize.cfg"

IMAGE_SRC_URI:ubi = "file://${UBINIZE_CFG}.tmpl"
IMAGE_TEMPLATE_FILES:ubi = "${UBINIZE_CFG}.tmpl"
IMAGE_TEMPLATE_VARS:ubi = "KERNEL_IMG INITRD_IMG DTB_IMG UBIFS_IMG FIT_IMG"

IMAGE_CMD:ubi() {
    if [ ! -e "${WORKDIR}/${UBINIZE_CFG}" ]; then
        die "UBINIZE_CFG does not contain ubinize config file."
    fi

    ${SUDO_CHROOT} /usr/sbin/ubinize ${UBINIZE_ARGS} \
                -o '${IMAGE_FILE_CHROOT}' '${PP_WORK}/${UBINIZE_CFG}'
}
IMAGE_CMD:ubi[depends] = "${PN}:do_transform_template"

# image conversions
IMAGE_CONVERSIONS = "gz xz"

CONVERSION_CMD:gz = "${SUDO_CHROOT} sh -c 'gzip -f -9 -n -c --rsyncable ${IMAGE_FILE_CHROOT} > ${IMAGE_FILE_CHROOT}.gz'"
CONVERSION_DEPS:gz = "gzip"

CONVERSION_CMD:xz = "${SUDO_CHROOT} sh -c 'xz -c ${XZ_OPTIONS} ${IMAGE_FILE_CHROOT} > ${IMAGE_FILE_CHROOT}.xz'"
CONVERSION_DEPS:xz = "xz-utils"
