# SDK Root filesystem
#
# This software is a part of ISAR.
# Copyright (C) 2015-2018 ilbers GmbH

DESCRIPTION = "Isar SDK Root filesystem"

LICENSE = "gpl-2.0"
LIC_FILES_CHKSUM = "file://${LAYERDIR_core}/licenses/COPYING.GPLv2;md5=751419260aa954499f7abaabaa882bbe"

SRC_URI = " \
    file://configscript.sh \
    file://README.sdk"
PV = "0.1"
PF = "${PN}-${HOST_DISTRO}-${HOST_ARCH}-${DISTRO_ARCH}"

TOOLCHAIN = "crossbuild-essential-${DISTRO_ARCH}"
TOOLCHAIN_${HOST_ARCH} = "build-essential"
TOOLCHAIN_i386 = "build-essential"

inherit rootfs
ROOTFS_ARCH = "${HOST_ARCH}"
ROOTFS_DISTRO = "${HOST_DISTRO}"
ROOTFSDIR = "${S}"
ROOTFS_PACKAGES = "${SDKCHROOT_PREINSTALL} ${TOOLCHAIN}"
ROOTFS_FEATURES += "copy-package-cache"

python() {
    if d.getVar("HOST_ARCH") not in ['i386', 'amd64']:
        raise bb.parse.SkipRecipe("SDK doesn't support {} as host".format(
            d.getVar("ROOTFS_ARCH")))
}

SDKCHROOT_PREINSTALL := "debhelper \
                           autotools-dev \
                           dpkg \
                           locales \
                           docbook-to-man \
                           apt \
                           automake \
                           devscripts \
                           equivs"

S = "${WORKDIR}/rootfs"

ROOTFS_CONFIGURE_COMMAND += "rootfs_configure_isar_apt_dir"
rootfs_configure_isar_apt_dir() {
    # Copy isar-apt instead of mounting:
    sudo cp -Trpfx ${REPO_ISAR_DIR}/${DISTRO} ${ROOTFSDIR}/isar-apt
}

ROOTFS_POSTPROCESS_COMMAND =+ "sdkchroot_install_files"
sdkchroot_install_files() {
    # Configure root filesystem
    sudo install -m 644 ${WORKDIR}/README.sdk ${S}
    sudo install -m 755 ${WORKDIR}/configscript.sh ${S}
    sudo chroot ${S} /configscript.sh  ${DISTRO_ARCH}
}
