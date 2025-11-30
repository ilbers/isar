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
INITRAMFS_GENERATOR_PKG ??= "initramfs-tools"
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
ROOTFS_PACKAGES = "${INITRAMFS_GENERATOR_PKG} ${INITRAMFS_PREINSTALL} ${INITRAMFS_INSTALL}"

# validate if have incompatible packages in the installation list
python do_validate_rootfs_packages () {
    # in Debian initramfs-tools specific packages should end or star
    # with initramfs
    # dracut specific packages end with dracut
    incompatible_initrd_packages = { 'initramfs-tools':['dracut'],
                                     'dracut':['initramfs']}
    initrd_generator = d.getVar("INITRAMFS_GENERATOR_PKG")
    for invalid_generator_idenitifier in incompatible_initrd_packages.get(initrd_generator):
        for pkg in d.getVar('ROOTFS_PACKAGES').split():
            if invalid_generator_idenitifier  in pkg:
                bb.error(f"{pkg} is incompatible with the selected generator '{initrd_generator}'")
}
addtask do_validate_rootfs_packages before do_rootfs_install
inherit rootfs
