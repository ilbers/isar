# This software is a part of ISAR.

# Make workdir and stamps machine-specific without changing common PN target
WORKDIR = "${TMPDIR}/work/${DISTRO}-${DISTRO_ARCH}/${PN}-${MACHINE}/${PV}-${PR}"
DEPLOYDIR = "${WORKDIR}/deploy"
STAMP = "${STAMPS_DIR}/${DISTRO}-${DISTRO_ARCH}/${PN}-${MACHINE}/${PV}-${PR}"
STAMPCLEAN = "${STAMPS_DIR}/${DISTRO}-${DISTRO_ARCH}/${PN}-${MACHINE}/*-*"

INITRAMFS_INSTALL ?= ""
INITRAMFS_PREINSTALL ?= ""
INITRAMFS_ROOTFS ?= "${WORKDIR}/rootfs"
INITRAMFS_IMAGE_NAME = "${INITRAMFS_FULLNAME}.initrd.img"
INITRD_DEPLOY_FILE = "${INITRAMFS_IMAGE_NAME}"

# Install proper kernel
INITRAMFS_INSTALL += "${@ ("linux-image-" + d.getVar("KERNEL_NAME")) if d.getVar("KERNEL_NAME") else ""}"

# Name of the initramfs including distro&machine names
INITRAMFS_FULLNAME = "${PN}-${DISTRO}-${MACHINE}"

# Bill-of-material
ROOTFS_MANIFEST_DEPLOY_DIR = "${DEPLOY_DIR_IMAGE}"
ROOTFS_PACKAGE_SUFFIX = "${INITRAMFS_FULLNAME}"

DEPENDS += "${INITRAMFS_INSTALL}"

ROOTFSDIR = "${INITRAMFS_ROOTFS}"
ROOTFS_FEATURES = "generate-manifest"
ROOTFS_PACKAGES = "initramfs-tools ${INITRAMFS_PREINSTALL} ${INITRAMFS_INSTALL}"

inherit rootfs
