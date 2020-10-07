# SDK Root filesystem
#
# This software is a part of ISAR.
# Copyright (C) 2015-2018 ilbers GmbH

DESCRIPTION = "Isar SDK Root filesystem"

LICENSE = "gpl-2.0"
LIC_FILES_CHKSUM = "file://${LAYERDIR_core}/licenses/COPYING.GPLv2;md5=751419260aa954499f7abaabaa882bbe"

SRC_URI = " \
    file://configscript.sh \
    file://relocate-sdk.sh \
    file://README.sdk"
PV = "0.1"

SDK_INSTALL ?= ""

DEPENDS += "${SDK_INSTALL}"

TOOLCHAIN = "crossbuild-essential-${DISTRO_ARCH}"
TOOLCHAIN_${HOST_ARCH} = "build-essential"
TOOLCHAIN_i386 = "build-essential"
TOOLCHAIN_append_compat-arch = " crossbuild-essential-${COMPAT_DISTRO_ARCH}"

inherit rootfs
ROOTFS_ARCH = "${HOST_ARCH}"
ROOTFS_DISTRO = "${HOST_DISTRO}"
ROOTFSDIR = "${S}"
ROOTFS_PACKAGES = "${SDK_PREINSTALL} ${SDK_INSTALL} ${TOOLCHAIN}"
ROOTFS_FEATURES += "clean-package-cache generate-manifest"
ROOTFS_MANIFEST_DEPLOY_DIR = "${DEPLOY_DIR_SDKCHROOT}"

python() {
    if d.getVar("HOST_ARCH") not in ['i386', 'amd64']:
        raise bb.parse.SkipRecipe("SDK doesn't support {} as host".format(
            d.getVar("ROOTFS_ARCH")))
}

SDK_PREINSTALL += " \
    debhelper \
    autotools-dev \
    dpkg \
    locales \
    docbook-to-man \
    apt \
    automake \
    devscripts \
    equivs"

SDK_INCLUDE_ISAR_APT ?= "0"

S = "${WORKDIR}/rootfs"

ROOTFS_CONFIGURE_COMMAND += "${@'rootfs_configure_isar_apt_dir' if d.getVar('SDK_INCLUDE_ISAR_APT') == '1' else ''}"
rootfs_configure_isar_apt_dir() {
    # Copy isar-apt instead of mounting:
    sudo cp -Trpfx ${REPO_ISAR_DIR}/${DISTRO} ${ROOTFSDIR}/isar-apt
}

ROOTFS_POSTPROCESS_COMMAND =+ "sdkchroot_install_files"
sdkchroot_install_files() {
    # Configure root filesystem
    sudo install -m 644 ${WORKDIR}/README.sdk ${S}
    sudo install -m 755 ${WORKDIR}/relocate-sdk.sh ${S}
    sudo install -m 755 ${WORKDIR}/configscript.sh ${S}
    sudo chroot ${S} /configscript.sh  ${DISTRO_ARCH}
}

do_sdkchroot_deploy[dirs] = "${DEPLOY_DIR_SDKCHROOT}"
do_sdkchroot_deploy() {
    ln -Tfsr "${ROOTFSDIR}" "${SDKCHROOT_DIR}"
}
addtask sdkchroot_deploy before do_build after do_rootfs

CLEANFUNCS = "clean_deploy"
clean_deploy() {
    rm -f "${SDKCHROOT_DIR}"
}
