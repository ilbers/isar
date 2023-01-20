# This software is a part of ISAR.
# Copyright (C) Siemens AG, 2019
#
# SPDX-License-Identifier: MIT
#
# This class extends the image.bbclass to supply the creation of a sdk

# hook up the -sdk image variant
BBCLASSEXTEND = "sdk"
BPN = "${PN}"

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

# Choose the correct toolchain: cross or native
python __anonymous() {
    mode = d.getVar('ISAR_CROSS_COMPILE', True)
    distro_arch = d.getVar('DISTRO_ARCH')
    if mode == "0" or d.getVar('HOST_ARCH') ==  distro_arch:
        toolchain = "build-essential"
    else:
        toolchain = "crossbuild-essential-" + distro_arch
    if d.getVar('ISAR_ENABLE_COMPAT_ARCH', True) == "1":
        toolchain += " crossbuild-essential-" + d.getVar('COMPAT_DISTRO_ARCH')
    d.setVar('TOOLCHAIN', toolchain)
}

# rootfs/image overrides for the SDK
ROOTFS_ARCH_class-sdk = "${HOST_ARCH}"
ROOTFS_DISTRO_class-sdk = "${HOST_DISTRO}"
ROOTFS_PACKAGES_class-sdk = "sdk-files ${TOOLCHAIN} ${SDK_PREINSTALL} ${SDK_INSTALL}"
ROOTFS_FEATURES_append_class-sdk = " clean-package-cache generate-manifest export-dpkg-status"
ROOTFS_MANIFEST_DEPLOY_DIR_class-sdk = "${DEPLOY_DIR_SDKCHROOT}"
ROOTFS_DPKGSTATUS_DEPLOY_DIR_class-sdk = "${DEPLOY_DIR_SDKCHROOT}"

IMAGE_FSTYPES_class-sdk = "${SDK_FORMATS}"

# bitbake dependencies
SDKDEPENDS += "sdk-files ${SDK_INSTALL}"
SDKDEPENDS_append_riscv64 = "${@' crossbuild-essential-riscv64' if d.getVar('ISAR_CROSS_COMPILE', True) == '1' and d.getVar('PN') != 'crossbuild-essential-riscv64' else ''}"
DEPENDS_class-sdk = "${SDKDEPENDS}"

SDKROOTFSDEPENDS = ""
SDKROOTFSDEPENDS_class-sdk = "${BPN}:do_rootfs"
do_rootfs_install[depends] += "${SDKROOTFSDEPENDS}"

SDKROOTFSVARDEPS = ""
SDKROOTFSVARDEPS_class-sdk = "SDK_INCLUDE_ISAR_APT"
do_rootfs_install[vardeps] += "${SDKROOTFSVARDEPS}"

# additional SDK steps
ROOTFS_CONFIGURE_COMMAND_append_class-sdk = " ${@'rootfs_configure_isar_apt_dir' if d.getVar('SDK_INCLUDE_ISAR_APT') == '1' else ''}"
rootfs_configure_isar_apt_dir() {
    # Copy isar-apt instead of mounting:
    sudo cp -Trpfx --reflink=auto ${REPO_ISAR_DIR}/${DISTRO} ${ROOTFSDIR}/isar-apt
}

ROOTFS_POSTPROCESS_COMMAND_prepend_class-sdk = "sdkchroot_configscript "
sdkchroot_configscript () {
    sudo chroot ${ROOTFSDIR} /configscript.sh ${DISTRO_ARCH}
}

ROOTFS_POSTPROCESS_COMMAND_append_class-sdk = " sdkchroot_finalize"
sdkchroot_finalize() {
    if [ "${SDK_INCLUDE_ISAR_APT}" = "0" ]; then
        # Remove isar-apt repo entry
        sudo rm -f ${ROOTFSDIR}/etc/apt/sources.list.d/isar-apt.list
    fi

    sudo umount -R ${ROOTFSDIR}/dev || true
    sudo umount ${ROOTFSDIR}/proc || true
    sudo umount -R ${ROOTFSDIR}/sys || true

    # Remove setup scripts
    sudo rm -f ${ROOTFSDIR}/chroot-setup.sh ${ROOTFSDIR}/configscript.sh

    # Make all links relative
    for link in $(find ${ROOTFSDIR}/ -type l); do
        target=$(readlink $link)

        if [ "${target#/}" != "${target}" ]; then
            basedir=$(dirname $link)
            new_target=$(realpath --no-symlinks -m --relative-to=$basedir ${ROOTFSDIR}/${target})

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

CLEANFUNCS_class-sdk = "clean_deploy"
clean_deploy() {
    rm -f "${SDKCHROOT_DIR}"
}

do_populate_sdk[noexec] = "1"
do_populate_sdk() {
    :
}
