# This software is a part of ISAR.

# Make workdir and stamps machine-specific without changing common PN target
WORKDIR = "${TMPDIR}/work/${DISTRO}-${DISTRO_ARCH}/${PN}-${MACHINE}/${PV}-${PR}"
STAMP = "${STAMPS_DIR}/${DISTRO}-${DISTRO_ARCH}/${PN}-${MACHINE}/${PV}-${PR}"
STAMPCLEAN = "${STAMPS_DIR}/${DISTRO}-${DISTRO_ARCH}/${PN}-${MACHINE}/*-*"

# Sstate also needs to be machine-specific
SSTATE_MANIFESTS = "${TMPDIR}/sstate-control/${MACHINE}-${DISTRO}-${DISTRO_ARCH}"

INITRAMFS_INSTALL ?= ""
INITRAMFS_PREINSTALL ?= ""
INITRAMFS_ROOTFS ?= "${WORKDIR}/rootfs"
INITRAMFS_IMAGE_FILE = "${DEPLOY_DIR_IMAGE}/${INITRAMFS_FULLNAME}.initrd.img"

# Install proper kernel
INITRAMFS_INSTALL += "${@ ("linux-image-" + d.getVar("KERNEL_NAME")) if d.getVar("KERNEL_NAME") else ""}"

# Name of the initramfs including distro&machine names
INITRAMFS_FULLNAME = "${PN}-${DISTRO}-${MACHINE}"

DEPENDS += "${INITRAMFS_INSTALL}"

ROOTFSDIR = "${INITRAMFS_ROOTFS}"
ROOTFS_FEATURES = ""
ROOTFS_PACKAGES = "initramfs-tools ${INITRAMFS_PREINSTALL} ${INITRAMFS_INSTALL}"

inherit rootfs

do_generate_initramfs[dirs] = "${DEPLOY_DIR_IMAGE}"
do_generate_initramfs[network] = "${TASK_USE_SUDO}"
do_generate_initramfs() {
    rootfs_do_mounts
    rootfs_do_qemu

    # generate reproducible initrd if requested
    if [ ! -z "${SOURCE_DATE_EPOCH}" ]; then
        export SOURCE_DATE_EPOCH="${SOURCE_DATE_EPOCH}"
    fi

    sudo -E chroot "${INITRAMFS_ROOTFS}" \
        update-initramfs -u -v

    if [ ! -e "${INITRAMFS_ROOTFS}/initrd.img" ]; then
        die "No initramfs was found after generation!"
    fi

    rm -rf "${INITRAMFS_IMAGE_FILE}"
    cp "${INITRAMFS_ROOTFS}/initrd.img" "${INITRAMFS_IMAGE_FILE}"
}
addtask generate_initramfs after do_rootfs before do_build
