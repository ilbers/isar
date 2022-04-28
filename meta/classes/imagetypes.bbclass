# This software is a part of ISAR.
# Copyright (C) 2021 Siemens AG
#
# SPDX-License-Identifier: MIT

#image type: tar
IMAGER_INSTALL_tar = "tar"
TAR_OPTIIONS ?= ""

IMAGE_CMD_tar() {
    ${SUDO_CHROOT} tar ${TAR_OPTIONS} -cvzf \
                 ${IMAGE_FILE_CHROOT} --one-file-system -C ${PP_ROOTFS} .
}

# image type: ext4
IMAGER_INSTALL_ext4 += "e2fsprogs"
MKE2FS_ARGS ?=  "-t ext4"

IMAGE_CMD_ext4() {
    truncate -s ${ROOTFS_SIZE}K '${IMAGE_FILE_HOST}'

    ${SUDO_CHROOT} /sbin/mke2fs ${MKE2FS_ARGS} \
                -F -d '${PP_ROOTFS}' '${IMAGE_FILE_CHROOT}'
}

# image type: cpio
IMAGER_INSTALL_cpio += "cpio"
CPIO_IMAGE_FORMAT ?= "newc"

IMAGE_CMD_cpio() {
    ${SUDO_CHROOT} \
        sh -c "cd ${PP_ROOTFS}; /usr/bin/find . | \
               /usr/bin/cpio -H ${CPIO_IMAGE_FORMAT} -o > \
               ${IMAGE_FILE_CHROOT}"
}

# image type: fit
MKIMAGE_ARGS ??= ""
FIT_IMAGE_SOURCE ??= "fitimage.its"
IMAGER_INSTALL_fit += "u-boot-tools device-tree-compiler"

IMAGE_CMD_fit() {
    if [ ! -e "${WORKDIR}/${FIT_IMAGE_SOURCE}" ]; then
        die "FIT_IMAGE_SOURCE does not contain fitimage source file"
    fi

    ${SUDO_CHROOT} /usr/bin/mkimage ${MKIMAGE_ARGS} \
                -f '${PP_WORK}/${FIT_IMAGE_SOURCE}' '${IMAGE_FILE_CHROOT}'
}
IMAGE_CMD_fit[depends] = "${PN}:do_transform_template"

# image type: ubifs
IMAGER_INSTALL_ubifs += "mtd-utils"
IMAGE_CMD_REQUIRED_ARGS_ubifs = "MKUBIFS_ARGS"

# glibc bug 23960 https://sourceware.org/bugzilla/show_bug.cgi?id=23960
# should not use QEMU on armhf target with mkfs.ubifs < v2.1.3
THIS_ISAR_CROSS_COMPILE := "${ISAR_CROSS_COMPILE}"
ISAR_CROSS_COMPILE_armhf = "${@bb.utils.contains('IMAGE_BASETYPES', 'ubifs', '1', '${THIS_ISAR_CROSS_COMPILE}', d)}"

IMAGE_CMD_ubifs() {
    ${SUDO_CHROOT} /usr/sbin/mkfs.ubifs ${MKUBIFS_ARGS} \
                -r '${PP_ROOTFS}' '${IMAGE_FILE_CHROOT}'
}

# image type: ubi
IMAGER_INSTALL_ubi += "mtd-utils"
IMAGE_CMD_REQUIRED_ARGS_ubi = "UBINIZE_ARGS"
UBINIZE_CFG ??= "ubinize.cfg"

IMAGE_CMD_ubi() {
    if [ ! -e "${WORKDIR}/${UBINIZE_CFG}" ]; then
        die "UBINIZE_CFG does not contain ubinize config file."
    fi

    ${SUDO_CHROOT} /usr/sbin/ubinize ${UBINIZE_ARGS} \
                -o '${IMAGE_FILE_CHROOT}' '${PP_WORK}/${UBINIZE_CFG}'
}
IMAGE_CMD_ubi[depends] = "${PN}:do_transform_template"

# image conversions
IMAGE_CONVERSIONS = "gz xz"

CONVERSION_CMD_gz = "${SUDO_CHROOT} sh -c 'gzip -f -9 -n -c --rsyncable ${IMAGE_FILE_CHROOT} > ${IMAGE_FILE_CHROOT}.gz'"
CONVERSION_DEPS_gz = "gzip"

XZ_MEMLIMIT ?= "50%"
XZ_THREADS ?= "${@oe.utils.cpu_count(at_least=2)}"
XZ_THREADS[vardepvalue] = "1"
XZ_OPTIONS ?= "--memlimit=${XZ_MEMLIMIT} --threads=${XZ_THREADS}"
XZ_OPTIONS[vardepsexclude] += "XZ_MEMLIMIT XZ_THREADS"
CONVERSION_CMD_xz = "${SUDO_CHROOT} sh -c 'xz -c ${XZ_OPTIONS} ${IMAGE_FILE_CHROOT} > ${IMAGE_FILE_CHROOT}.xz'"
CONVERSION_DEPS_xz = "xz-utils"
