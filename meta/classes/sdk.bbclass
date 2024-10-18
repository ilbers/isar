# This software is a part of ISAR.
# Copyright (C) Siemens AG, 2019
#
# SPDX-License-Identifier: MIT
#
# This class extends the image.bbclass to supply the creation of a sdk

inherit crossvars

# hook up the -sdk image variant
BBCLASSEXTEND = "sdk"

python sdk_virtclass_handler() {
    pn = e.data.getVar('PN')
    if pn.endswith('-sdk'):
        e.data.setVar('BPN', pn[:-len('-sdk')])
        e.data.appendVar('OVERRIDES', ':class-sdk')
        # sdkchroot deploy only for sdk image
        bb.build.addtask('deploy_sdkchroot', 'do_build', 'do_rootfs', d)
        bb.build.deltask('copy_boot_files', d)
    else:
        # add do_populate_sdk only to the non-sdk variant
        # it only exists to preserve the interface...
        bb.build.addtask('populate_sdk', '', '', e.data)
        e.data.appendVarFlag('do_populate_sdk', 'depends', '${BPN}-sdk:do_build')
        e.data.appendVarFlag('do_clean', 'depends', '${BPN}-sdk:do_clean')
}
addhandler sdk_virtclass_handler
sdk_virtclass_handler[eventmask] = "bb.event.RecipePreFinalise"

# SDK settings
SDK_INCLUDE_ISAR_APT ?= "0"
SDK_FORMATS ?= "tar.xz"
SDK_INSTALL ?= ""
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

def get_rootfs_distro(d):
    host_arch = d.getVar('HOST_ARCH')
    distro_arch = d.getVar('DISTRO_ARCH')
    if host_arch == distro_arch:
        return d.getVar('DISTRO')
    else:
        return d.getVar('HOST_DISTRO')

# rootfs/image overrides for the SDK
ROOTFS_ARCH:class-sdk = "${HOST_ARCH}"
ROOTFS_DISTRO:class-sdk = "${@get_rootfs_distro(d)}"
ROOTFS_PACKAGES:class-sdk = "sdk-files ${SDK_TOOLCHAIN} ${SDK_PREINSTALL} ${@isar_multiarch_packages('SDK_INSTALL', d)}"
ROOTFS_FEATURES:append:class-sdk = " clean-package-cache generate-manifest export-dpkg-status"
ROOTFS_MANIFEST_DEPLOY_DIR:class-sdk = "${DEPLOY_DIR_SDKCHROOT}"
ROOTFS_DPKGSTATUS_DEPLOY_DIR:class-sdk = "${DEPLOY_DIR_SDKCHROOT}"

IMAGE_FSTYPES:class-sdk = "${SDK_FORMATS}"
TAR_TRANSFORM:class-sdk = " --transform='s|rootfs|${IMAGE_FULLNAME}|'"

# bitbake dependencies
SDKDEPENDS += "sdk-files ${SDK_INSTALL}"
DEPENDS:class-sdk = "${SDKDEPENDS}"

SDKROOTFSDEPENDS = ""
SDKROOTFSDEPENDS:class-sdk = "${BPN}:do_rootfs"
do_rootfs_install[depends] += "${SDKROOTFSDEPENDS}"

SDKROOTFSVARDEPS = ""
SDKROOTFSVARDEPS:class-sdk = "SDK_INCLUDE_ISAR_APT"
do_rootfs_install[vardeps] += "${SDKROOTFSVARDEPS}"

ROOTFS_POSTPROCESS_COMMAND:remove = "${@'rootfs_cleanup_isar_apt' if bb.utils.to_boolean(d.getVar('SDK_INCLUDE_ISAR_APT')) else ''}"

# additional SDK steps
ROOTFS_CONFIGURE_COMMAND:append:class-sdk = " ${@'rootfs_configure_isar_apt_dir' if bb.utils.to_boolean(d.getVar('SDK_INCLUDE_ISAR_APT')) else ''}"
rootfs_configure_isar_apt_dir() {
    # Copy isar-apt instead of mounting:
    sudo cp -Trpfx --reflink=auto ${REPO_ISAR_DIR}/${DISTRO} ${ROOTFSDIR}/isar-apt
}

ROOTFS_POSTPROCESS_COMMAND:prepend:class-sdk = "sdkchroot_configscript "
sdkchroot_configscript () {
    sudo chroot ${ROOTFSDIR} /configscript.sh ${DISTRO_ARCH}
}

ROOTFS_POSTPROCESS_COMMAND:append:class-sdk = " sdkchroot_finalize"
sdkchroot_finalize() {
    mountpoint -q "${ROOTFSDIR}/dev/pts" && \
        sudo umount "${ROOTFSDIR}/dev/pts"
    mountpoint -q "${ROOTFSDIR}/dev/shm" && \
        sudo umount "${ROOTFSDIR}/dev/shm"
    mountpoint -q "${ROOTFSDIR}/dev" && \
        sudo umount "${ROOTFSDIR}/dev"
    mountpoint -q "${ROOTFSDIR}/proc" && \
        sudo umount "${ROOTFSDIR}/proc"
    mountpoint -q "${ROOTFSDIR}/sys" && \
        sudo umount "${ROOTFSDIR}/sys"

    # Remove setup scripts
    sudo rm -f ${ROOTFSDIR}/chroot-setup.sh ${ROOTFSDIR}/configscript.sh

    # Make all links relative
    for link in $(find ${ROOTFSDIR}/ -type l); do
        target=$(readlink $link)

        # Enter into if condition if target has a leading /
        if [ "${target#/}" != "${target}" ]; then
            basedir=$(dirname $link)
            new_target=$(realpath --no-symlinks -m --relative-to=$basedir ${ROOTFSDIR}${target})

            # remove first to allow rewriting directory links
            sudo rm $link
            sudo ln -s $new_target $link
        fi
    done

    # Set up sysroot wrapper
    for tool_pattern in "gcc-[0-9]*" "g++-[0-9]*" "cpp-[0-9]*" "ld.bfd" "ld.gold"; do
        for tool in $(find ${ROOTFSDIR}/usr/bin -type f -name "*-linux-gnu*-${tool_pattern}"); do
            sudo mv "${tool}" "${tool}.bin"
            sudo ln -sf gcc-sysroot-wrapper.sh ${tool}
        done
    done
}

do_deploy_sdkchroot[dirs] = "${DEPLOY_DIR_SDKCHROOT}"
do_deploy_sdkchroot() {
    ln -Tfsr "${ROOTFSDIR}" "${SDKCHROOT_DIR}"
}

CLEANFUNCS:class-sdk = "clean_deploy"
clean_deploy() {
    rm -f "${SDKCHROOT_DIR}"
}

do_populate_sdk[noexec] = "1"
do_populate_sdk() {
    :
}
