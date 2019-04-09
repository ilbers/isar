# This software is a part of ISAR.
# Copyright (C) 2015-2017 ilbers GmbH

PF = "${PN}-${DISTRO}-${MACHINE}"

IMAGE_INSTALL ?= ""
IMAGE_TYPE    ?= "ext4-img"
IMAGE_ROOTFS   = "${WORKDIR}/rootfs"

IMAGE_INSTALL += "${@ ("linux-image-" + d.getVar("KERNEL_NAME", True)) if d.getVar("KERNEL_NAME", True) else ""}"

# Name of the image including distro&machine names
IMAGE_FULLNAME = "${PF}"

# These variables are used by wic and start_vm
KERNEL_IMAGE ?= "vmlinuz"
INITRD_IMAGE ?= "initrd.img"

# Useful variables for imager implementations:
PP = "/home/builder/${PN}"
PP_DEPLOY = "${PP}/deploy"
PP_ROOTFS = "${PP}/rootfs"
PP_WORK = "${PP}/work"

BUILDROOT = "${BUILDCHROOT_DIR}${PP}"
BUILDROOT_DEPLOY = "${BUILDCHROOT_DIR}${PP_DEPLOY}"
BUILDROOT_ROOTFS = "${BUILDCHROOT_DIR}${PP_ROOTFS}"
BUILDROOT_WORK = "${BUILDCHROOT_DIR}${PP_WORK}"

def cfg_script(d):
    cf = d.getVar('DISTRO_CONFIG_SCRIPT', True) or ''
    if cf:
        return 'file://' + cf
    return ''

FILESPATH =. "${LAYERDIR_core}/conf/distro:"
SRC_URI += "${@ cfg_script(d) }"

DEPENDS += "${IMAGE_INSTALL} ${IMAGE_TRANSIENT_PACKAGES}"

IMAGE_TRANSIENT_PACKAGES += "isar-cfg-localepurge isar-cfg-rootpw"

ISAR_RELEASE_CMD_DEFAULT = "git -C ${LAYERDIR_core} describe --tags --dirty --match 'v[0-9].[0-9]*'"
ISAR_RELEASE_CMD ?= "${ISAR_RELEASE_CMD_DEFAULT}"

image_do_mounts() {
    sudo flock ${MOUNT_LOCKFILE} -c ' \
        mkdir -p "${BUILDROOT_DEPLOY}" "${BUILDROOT_ROOTFS}" "${BUILDROOT_WORK}"
        mount --bind "${DEPLOY_DIR_IMAGE}" "${BUILDROOT_DEPLOY}"
        mount --bind "${IMAGE_ROOTFS}" "${BUILDROOT_ROOTFS}"
        mount --bind "${WORKDIR}" "${BUILDROOT_WORK}"
    '
    buildchroot_do_mounts
}

inherit isar-bootstrap-helper
inherit image-sdk-extension
inherit image-cache-extension
inherit image-tools-extension

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
        ["sudo", "du", "-xs", "--block-size=1k", d.getVar("IMAGE_ROOTFS", True)]
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

isar_image_gen_fstab() {
    cat > ${WORKDIR}/fstab << EOF
# Begin /etc/fstab
/dev/root	/		auto		defaults		0	0
proc		/proc		proc		nosuid,noexec,nodev	0	0
sysfs		/sys		sysfs		nosuid,noexec,nodev	0	0
devpts		/dev/pts	devpts		gid=5,mode=620		0	0
tmpfs		/run		tmpfs		defaults		0	0
devtmpfs	/dev		devtmpfs	mode=0755,nosuid	0	0

# End /etc/fstab
EOF
}

isar_image_gen_rootfs() {
    setup_root_file_system --clean --keep-apt-cache \
        --fstab "${WORKDIR}/fstab" \
        "${IMAGE_ROOTFS}" ${IMAGE_PREINSTALL} ${IMAGE_INSTALL}
}

isar_image_conf_rootfs() {
    # Configure root filesystem
    if [ -n "${DISTRO_CONFIG_SCRIPT}" ]; then
        sudo install -m 755 "${WORKDIR}/${DISTRO_CONFIG_SCRIPT}" "${IMAGE_ROOTFS}"
        TARGET_DISTRO_CONFIG_SCRIPT="$(basename ${DISTRO_CONFIG_SCRIPT})"
        sudo chroot ${IMAGE_ROOTFS} "/$TARGET_DISTRO_CONFIG_SCRIPT" \
                                    "${MACHINE_SERIAL}" "${BAUDRATE_TTY}"
        sudo rm "${IMAGE_ROOTFS}/$TARGET_DISTRO_CONFIG_SCRIPT"
   fi
}

isar_image_cleanup() {
    # Cleanup
    sudo sh -c ' \
        rm "${IMAGE_ROOTFS}/etc/apt/sources.list.d/isar-apt.list"
        test ! -e "${IMAGE_ROOTFS}/usr/share/doc/qemu-user-static" && \
            find "${IMAGE_ROOTFS}/usr/bin" \
                -maxdepth 1 -name 'qemu-*-static' -type f -delete
             umount -l ${IMAGE_ROOTFS}/isar-apt
        rmdir ${IMAGE_ROOTFS}/isar-apt
        umount -l ${IMAGE_ROOTFS}/dev
        umount -l ${IMAGE_ROOTFS}/proc
        umount -l ${IMAGE_ROOTFS}/sys
        rm -f "${IMAGE_ROOTFS}/etc/apt/apt.conf.d/55isar-fallback.conf"
        if [ "${ISAR_USE_CACHED_BASE_REPO}" = "1" ]; then
            umount -l ${IMAGE_ROOTFS}/base-apt
            rmdir ${IMAGE_ROOTFS}/base-apt
            # Replace the local apt we bootstrapped with the
            # APT sources initially defined in DISTRO_APT_SOURCES
            rm -f "${IMAGE_ROOTFS}/etc/apt/sources.list.d/base-apt.list"
            mv "${IMAGE_ROOTFS}/etc/apt/sources-list" \
                "${IMAGE_ROOTFS}/etc/apt/sources.list.d/bootstrap.list"
        fi
        rm -f "${IMAGE_ROOTFS}/etc/apt/sources-list"
    '
}

do_rootfs_install[depends] = "isar-apt:do_cache_config isar-bootstrap-target:do_bootstrap"
do_rootfs_install[deptask] = "do_deploy_deb"
do_rootfs_install[root_cleandirs] = "${IMAGE_ROOTFS} \
                             ${IMAGE_ROOTFS}/isar-apt"
do_rootfs_install() {
    isar_image_gen_fstab
    isar_image_gen_rootfs
    isar_image_conf_rootfs
    isar_image_cleanup
}
addtask rootfs_install before do_build after do_unpack

do_mark_rootfs() {
    BUILD_ID=$(get_build_id)
    update_etc_os_release \
        --build-id "${BUILD_ID}" --variant "${DESCRIPTION}" \
        "${IMAGE_ROOTFS}"
}
addtask mark_rootfs before do_rootfs_postprocess after do_rootfs_install

do_copy_boot_files[dirs] = "${DEPLOY_DIR_IMAGE}"
do_copy_boot_files() {
    if [ -n "${KERNEL_IMAGE}" ]; then
        cp -f ${IMAGE_ROOTFS}/boot/${@get_image_name(d, 'vmlinuz')[0]} ${DEPLOY_DIR_IMAGE}/${KERNEL_IMAGE}
    fi

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
addtask copy_boot_files before do_rootfs_postprocess after do_rootfs_install

python do_rootfs_postprocess() {
    """Virtual task"""
    pass
}
addtask rootfs_postprocess before do_build after do_rootfs_install

python do_rootfs() {
    """Virtual task"""
    pass
}
addtask rootfs before do_build after do_rootfs_postprocess

python do_image_tools() {
    """Virtual task"""
    pass
}
addtask image_tools before do_build after do_rootfs

python do_image() {
    """Virtual task"""
    pass
}
addtask image before do_build after do_image_tools

python do_deploy() {
    """Virtual task"""
    pass
}
addtask deploy before do_build after do_image

# Last so that the image type can overwrite tasks if needed
inherit ${IMAGE_TYPE}
