# This software is a part of ISAR.
# Copyright (C) 2015-2017 ilbers GmbH

IMAGE_INSTALL ?= ""
IMAGE_TYPE    ?= "ext4-img"
IMAGE_ROOTFS   = "${WORKDIR}/rootfs"

IMAGE_INSTALL += "${@ ("linux-image-" + d.getVar("KERNEL_NAME", True)) if d.getVar("KERNEL_NAME", True) else ""}"

# Name of the image including distro&machine names
IMAGE_FULLNAME = "${PN}-${DISTRO}-${MACHINE}"

# These variables are used by wic and start_vm
KERNEL_IMAGE ?= "${@get_image_name(d, 'vmlinuz')[1]}"
INITRD_IMAGE ?= "${@get_image_name(d, 'initrd.img')[1]}"

# Useful variables for imager implementations:
PP = "/home/builder/${PN}"
PP_DEPLOY = "${PP}/deploy"
PP_ROOTFS = "${PP}/rootfs"
PP_WORK = "${PP}/work"

BUILDROOT = "${BUILDCHROOT_DIR}${PP}"
BUILDROOT_DEPLOY = "${BUILDCHROOT_DIR}${PP_DEPLOY}"
BUILDROOT_ROOTFS = "${BUILDCHROOT_DIR}${PP_ROOTFS}"
BUILDROOT_WORK = "${BUILDCHROOT_DIR}${PP_WORK}"

image_do_mounts() {
    sudo flock ${MOUNT_LOCKFILE} -c ' \
        mkdir -p "${BUILDROOT_DEPLOY}" "${BUILDROOT_ROOTFS}" "${BUILDROOT_WORK}"
        mount --bind "${DEPLOY_DIR_IMAGE}" "${BUILDROOT_DEPLOY}"
        mount --bind "${IMAGE_ROOTFS}" "${BUILDROOT_ROOTFS}"
        mount --bind "${WORKDIR}" "${BUILDROOT_WORK}"
    '
    buildchroot_do_mounts
}

inherit ${IMAGE_TYPE}

# Extra space for rootfs in MB
ROOTFS_EXTRA ?= "64"

def get_image_name(d, name_link):
    S = d.getVar("IMAGE_ROOTFS", True)
    path_link = os.path.join(S, name_link)

    # If path_link does not exist, it might be a symlink
    # in the target rootfs.  This block attempts to resolve
    # it relative to the rootfs location.
    if not os.path.exists(path_link):
        path_link = os.path.join(
            S,
            os.path.relpath(
                os.path.realpath(path_link),
                "/",
            ),
        )

    if os.path.exists(path_link):
        base = os.path.basename(os.path.realpath(path_link))
        full = d.getVar("IMAGE_FULLNAME", True) + "." + base
        return [base, full]

    return ["", ""]

def get_rootfs_size(d):
    import subprocess
    rootfs_extra = int(d.getVar("ROOTFS_EXTRA", True))

    output = subprocess.check_output(
        ["sudo", "du", "-s", "--block-size=1k", d.getVar("IMAGE_ROOTFS", True)]
    )
    base_size = int(output.split()[0])

    return base_size + rootfs_extra * 1024

# here we call a command that should describe your whole build system,
# this could be "git describe" or something similar.
# set ISAR_RELEASE_CMD to customize, or override do_mark_rootfs to do something
# completely different
get_build_id() {
	if [ $(echo ${BBLAYERS} | wc -w) -ne 2 ] &&
	   [ "${ISAR_RELEASE_CMD}" = "${ISAR_RELEASE_CMD_DEFAULT}" ]; then
		bbwarn "You are using external layers that will not be" \
		       "considered in the build_id. Consider changing" \
		       "ISAR_RELEASE_CMD."
	fi
	if ! ${ISAR_RELEASE_CMD} 2>/dev/null; then
		bbwarn "\"${ISAR_RELEASE_CMD}\" failed, returning empty build_id."
		echo ""
	fi
}

python set_image_size () {
    rootfs_size = get_rootfs_size(d)
    d.setVar('ROOTFS_SIZE', str(rootfs_size))
    d.setVarFlag('ROOTFS_SIZE', 'export', '1')
}

do_rootfs[stamp-extra-info] = "${MACHINE}-${DISTRO}"
do_rootfs[depends] = "isar-apt:do_cache_config isar-bootstrap-target:do_bootstrap"

do_rootfs() {
    die "No root filesystem function defined, please implement in your recipe"
}

addtask rootfs before do_build after do_unpack
do_rootfs[deptask] = "do_deploy_deb"

do_mark_rootfs() {
    BUILD_ID=$(get_build_id)
    update_etc_os_release \
        --build-id "${BUILD_ID}" --variant "${DESCRIPTION}" \
        "${IMAGE_ROOTFS}"
}

addtask mark_rootfs before do_copy_boot_files do_transform_template after do_rootfs

do_copy_boot_files() {
    KERNEL_IMAGE=${@get_image_name(d, 'vmlinuz')[1]}
    if [ -n "${KERNEL_IMAGE}" ]; then
        cp -f ${IMAGE_ROOTFS}/boot/${@get_image_name(d, 'vmlinuz')[0]} ${DEPLOY_DIR_IMAGE}/${KERNEL_IMAGE}
    fi

    INITRD_IMAGE=${@get_image_name(d, 'initrd.img')[1]}
    if [ -n "${INITRD_IMAGE}" ]; then
        sudo cp -f ${IMAGE_ROOTFS}/boot/${@get_image_name(d, 'initrd.img')[0]} ${DEPLOY_DIR_IMAGE}/${INITRD_IMAGE}
    fi

    # Check DTB_FILE via inline python to handle unset case:
    if [ -n "${@d.getVar('DTB_FILE', True) or ""}" ]; then
        dtb="$(find '${IMAGE_ROOTFS}/usr/lib' -type f \
                    -iwholename '*linux-image-*/${DTB_FILE}' | head -1)"

        if [ -z "$dtb" -o ! -e "$dtb" ]; then
            die "${DTB_FILE} not found"
        fi

        cp -f "$dtb" "${DEPLOY_DIR_IMAGE}/${DTB_FILE}"
    fi
}

addtask copy_boot_files before do_build after do_rootfs
do_copy_boot_files[dirs] = "${DEPLOY_DIR_IMAGE}"
do_copy_boot_files[stamp-extra-info] = "${DISTRO}-${MACHINE}"

SDKCHROOT_DIR = "${TMPDIR}/work/${DISTRO}-${DISTRO_ARCH}/sdkchroot-${HOST_DISTRO}-${HOST_ARCH}"

do_populate_sdk() {
    # Copy isar-apt with deployed Isar packages
    sudo cp -Trpfx ${REPO_ISAR_DIR}/${DISTRO}  ${SDKCHROOT_DIR}/rootfs/isar-apt

    # Purge apt cache to make image slimmer
    sudo rm -rf ${SDKCHROOT_DIR}/rootfs/var/cache/apt/*

    sudo umount -R ${SDKCHROOT_DIR}/rootfs/dev || true
    sudo umount ${SDKCHROOT_DIR}/rootfs/proc || true
    sudo umount -R ${SDKCHROOT_DIR}/rootfs/sys || true

    # Remove setup scripts
    sudo rm -f ${SDKCHROOT_DIR}/rootfs/chroot-setup.sh ${SDKCHROOT_DIR}/rootfs/configscript.sh

    # Copy mount_chroot.sh for convenience
    sudo cp ${ISARROOT}/scripts/mount_chroot.sh ${SDKCHROOT_DIR}/rootfs

    # Create SDK archive
    sudo tar -C ${SDKCHROOT_DIR} --transform="s|^rootfs|sdk-${DISTRO}-${DISTRO_ARCH}|" \
        -c rootfs | xz -T0 > ${DEPLOY_DIR_IMAGE}/sdk-${DISTRO}-${DISTRO_ARCH}.tar.xz

    # Install deployment link for local use
    ln -Tfsr ${SDKCHROOT_DIR}/rootfs ${DEPLOY_DIR_IMAGE}/sdk-${DISTRO}-${DISTRO_ARCH}
}

do_populate_sdk[stamp-extra-info] = "${MACHINE}-${DISTRO}"
do_populate_sdk[depends] = "sdkchroot:do_build"

addtask populate_sdk after do_rootfs

inherit base-apt-helper

do_cache_base_repo[depends] = "base-apt:do_cache_config"
do_cache_base_repo[lockfiles] = "${REPO_BASE_DIR}/isar.lock"
do_cache_base_repo[stamp-extra-info] = "${MACHINE}-${DISTRO}"

do_cache_base_repo() {
    if [ -d ${WORKDIR}/apt_cache ]; then
        populate_base_apt ${WORKDIR}/apt_cache
    fi

    if [ -d ${BUILDCHROOT_HOST_DIR}/var/cache/apt ]; then
        populate_base_apt ${BUILDCHROOT_HOST_DIR}/var/cache/apt
    fi

    if [ -d ${BUILDCHROOT_TARGET_DIR}/var/cache/apt ]; then
        populate_base_apt ${BUILDCHROOT_TARGET_DIR}/var/cache/apt
    fi
}

addtask cache_base_repo after do_rootfs do_install_imager_deps

# Imager are expected to run natively, thus will use the target buildchroot.
ISAR_CROSS_COMPILE = "0"

inherit buildchroot

IMAGER_INSTALL ??= ""
IMAGER_BUILD_DEPS ??= ""
DEPENDS += "${IMAGER_BUILD_DEPS}"

python () {
    if d.getVar('IMAGE_TYPE', True) == 'wic-img':
        d.appendVar('IMAGER_INSTALL',
                    ' ' + d.getVar('WIC_IMAGER_INSTALL', True))
}

do_install_imager_deps() {
    if [ -z "${@d.getVar("IMAGER_INSTALL", True).strip()}" ]; then
        exit
    fi

    buildchroot_do_mounts

    E="${@bb.utils.export_proxies(d)}"
    sudo -E chroot ${BUILDCHROOT_DIR} sh -c ' \
        apt-get update \
            -o Dir::Etc::sourcelist="sources.list.d/isar-apt.list" \
            -o Dir::Etc::sourceparts="-" \
            -o APT::Get::List-Cleanup="0"
        apt-get -o Debug::pkgProblemResolver=yes --no-install-recommends -y \
            --allow-unauthenticated install \
            ${IMAGER_INSTALL}'
}

do_install_imager_deps[depends] = "buildchroot-target:do_build"
do_install_imager_deps[deptask] = "do_deploy_deb"
do_install_imager_deps[lockfiles] += "${REPO_ISAR_DIR}/isar.lock"
do_install_imager_deps[stamp-extra-info] = "${DISTRO}-${MACHINE}"

addtask install_imager_deps before do_build
