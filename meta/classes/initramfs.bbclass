# This software is a part of ISAR.

# Make workdir and stamps machine-specific without changing common PN target
WORKDIR = "${TMPDIR}/work/${DISTRO}-${DISTRO_ARCH}/${PN}-${MACHINE}/${PV}-${PR}"
DEPLOYDIR = "${WORKDIR}/deploy"
STAMP = "${STAMPS_DIR}/${DISTRO}-${DISTRO_ARCH}/${PN}-${MACHINE}/${PV}-${PR}"
STAMPCLEAN = "${STAMPS_DIR}/${DISTRO}-${DISTRO_ARCH}/${PN}-${MACHINE}/*-*"

# Sstate also needs to be machine-specific
SSTATE_MANIFESTS = "${TMPDIR}/sstate-control/${MACHINE}-${DISTRO}-${DISTRO_ARCH}"
SSTATETASKS += "do_generate_initramfs"

INITRAMFS_INSTALL ?= ""
INITRAMFS_PREINSTALL ?= ""
INITRAMFS_ROOTFS ?= "${WORKDIR}/rootfs"
INITRAMFS_IMAGE_NAME = "${INITRAMFS_FULLNAME}.initrd.img"
INITRAMFS_IMAGE_FILE = "${DEPLOY_DIR_IMAGE}/${INITRAMFS_IMAGE_NAME}"

# Install proper kernel
INITRAMFS_INSTALL += "${@ ("linux-image-" + d.getVar("KERNEL_NAME")) if d.getVar("KERNEL_NAME") else ""}"

# Name of the initramfs including distro&machine names
INITRAMFS_FULLNAME = "${PN}-${DISTRO}-${MACHINE}"

DEPENDS += "${INITRAMFS_INSTALL}"

ROOTFSDIR = "${INITRAMFS_ROOTFS}"
ROOTFS_FEATURES = ""
ROOTFS_PACKAGES = "initramfs-tools ${INITRAMFS_PREINSTALL} ${INITRAMFS_INSTALL}"

inherit rootfs

do_generate_initramfs[network] = "${TASK_USE_SUDO}"
do_generate_initramfs[cleandirs] += "${DEPLOYDIR}"
do_generate_initramfs[sstate-inputdirs] = "${DEPLOYDIR}"
do_generate_initramfs[sstate-outputdirs] = "${DEPLOY_DIR_IMAGE}"
do_generate_initramfs() {
    rootfs_do_mounts
    rootfs_do_qemu

    sudo -E chroot "${INITRAMFS_ROOTFS}" sh -c '\
        export kernel_version=$(basename /boot/vmlinu[xz]* | cut -d'-' -f2-); \
        if [ -n "$kernel_version" ]; then \
          update-initramfs -u -v -k "$kernel_version"; \
        else \
          update-initramfs -u -v ;  \
        fi'

    if [ ! -e "${INITRAMFS_ROOTFS}/initrd.img" ]; then
        bberror "No initramfs was found after generation!"
    fi
    cp ${INITRAMFS_ROOTFS}/initrd.img ${DEPLOYDIR}/${INITRAMFS_IMAGE_NAME}
}
addtask generate_initramfs after do_rootfs before do_build

python do_generate_initramfs_setscene () {
    sstate_setscene(d)
}
addtask do_generate_initramfs_setscene
