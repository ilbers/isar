# This software is a part of ISAR.
# Copyright (C) 2015-2017 ilbers GmbH

IMAGE_INSTALL ?= ""
IMAGE_TYPE    ?= "ext4-img"
IMAGE_ROOTFS   = "${WORKDIR}/rootfs"

def get_image_name(d, name_link):
    S = d.getVar("IMAGE_ROOTFS", True)
    path_link = os.path.join(S, name_link)
    if os.path.lexists(path_link):
        return os.path.basename(os.path.realpath(path_link))
    return ""

# These variables are used by wic and start_vm
KERNEL_IMAGE ?= "${@get_image_name(d, 'vmlinuz')}"
INITRD_IMAGE ?= "${@get_image_name(d, 'initrd.img')}"

inherit ${IMAGE_TYPE}

do_rootfs[stamp-extra-info] = "${MACHINE}-${DISTRO}"
do_rootfs[depends] = "isar-apt:do_cache_config"

do_rootfs() {
    die "No root filesystem function defined, please implement in your recipe"
}

addtask rootfs before do_build after do_unpack
do_rootfs[deptask] = "do_deploy_deb"

do_copy_boot_files() {
    KERNEL_IMAGE=${@get_image_name(d, 'vmlinuz')}
    if [ -n "${KERNEL_IMAGE}" ]; then
        cp -f ${IMAGE_ROOTFS}/boot/${KERNEL_IMAGE} ${DEPLOY_DIR_IMAGE}
    fi

    INITRD_IMAGE=${@get_image_name(d, 'initrd.img')}
    if [ -n "${INITRD_IMAGE}" ]; then
        sudo cp -f ${IMAGE_ROOTFS}/boot/${INITRD_IMAGE} ${DEPLOY_DIR_IMAGE}
    fi
}

addtask copy_boot_files before do_build after do_rootfs
do_copy_boot_files[dirs] = "${DEPLOY_DIR_IMAGE}"
do_copy_boot_files[stamp-extra-info] = "${DISTRO}-${MACHINE}"
