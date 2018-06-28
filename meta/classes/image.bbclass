# This software is a part of ISAR.
# Copyright (C) 2015-2017 ilbers GmbH

IMAGE_INSTALL ?= ""
IMAGE_TYPE    ?= "ext4-img"
IMAGE_ROOTFS   = "${WORKDIR}/rootfs"

IMAGE_INSTALL += "${@ ("linux-image-" + d.getVar("KERNEL_NAME", True)) if d.getVar("KERNEL_NAME", True) else ""}"

# Extra space for rootfs in MB
ROOTFS_EXTRA ?= "64"

def get_image_name(d, name_link):
    S = d.getVar("IMAGE_ROOTFS", True)
    path_link = os.path.join(S, name_link)
    if os.path.exists(path_link):
        base = os.path.basename(os.path.realpath(path_link))
        full = base
        full += "_" + d.getVar("DISTRO", True)
        full += "-" + d.getVar("MACHINE", True)
        return [base, full]
    if os.path.islink(path_link):
        return get_image_name(d, os.path.relpath(os.path.realpath(path_link),
                                                 '/'))
    return ["", ""]

def get_rootfs_size(d):
    import subprocess
    rootfs_extra = int(d.getVar("ROOTFS_EXTRA", True))

    output = subprocess.check_output(['sudo', 'du', '-s', '--block-size=1k',
                                      d.getVar("IMAGE_ROOTFS", True)])
    base_size = int(output.split()[0])

    return base_size + rootfs_extra * 1024

# we assume that one git commit can describe the whole image, so you should be
# using submodules, kas, or something like that
# set ISAR_GIT_RELEASE_PATH to that one "most significant" layer
# when not using git, override do_mark_rootfs
def get_build_id(d):
    import subprocess
    if (len(d.getVar("BBLAYERS", True).strip().split(' ')) != 2 and
        (d.getVar("ISAR_GIT_RELEASE_PATH", True) ==
         d.getVar("LAYERDIR_isar", True))):
        bb.warn('You are using external layers that will not be considered' +
                ' in the build_id. Considder setting ISAR_GIT_RELEASE_PATH.')
    base = ["git", "-C", d.getVar("ISAR_GIT_RELEASE_PATH", True)]
    if (0 == subprocess.call(base + ["rev-parse"])):
        v = subprocess.check_output(base +
                                    ["describe", "--long", "--dirty",
                                     "--always"], universal_newlines=True)
        return v.rstrip()
    return ""

python set_image_size () {
    rootfs_size = get_rootfs_size(d)
    d.setVar('ROOTFS_SIZE', str(rootfs_size))
    d.setVarFlag('ROOTFS_SIZE', 'export', '1')
}

# These variables are used by wic and start_vm
KERNEL_IMAGE ?= "${@get_image_name(d, 'vmlinuz')[1]}"
INITRD_IMAGE ?= "${@get_image_name(d, 'initrd.img')[1]}"

inherit ${IMAGE_TYPE}

do_rootfs[stamp-extra-info] = "${MACHINE}-${DISTRO}"
do_rootfs[depends] = "isar-apt:do_cache_config isar-bootstrap-target:do_deploy"

do_rootfs() {
    die "No root filesystem function defined, please implement in your recipe"
}

addtask rootfs before do_build after do_unpack
do_rootfs[deptask] = "do_deploy_deb"

do_mark_rootfs() {
    update_etc_os_release \
        --build-id "${@get_build_id(d)}" --variant "${DESCRIPTION}" \
        "${IMAGE_ROOTFS}"
}

addtask mark_rootfs before do_copy_boot_files after do_rootfs

do_copy_boot_files() {
    KERNEL_IMAGE=${@get_image_name(d, 'vmlinuz')[1]}
    if [ -n "${KERNEL_IMAGE}" ]; then
        cp -f ${IMAGE_ROOTFS}/boot/${@get_image_name(d, 'vmlinuz')[0]} ${DEPLOY_DIR_IMAGE}/${KERNEL_IMAGE}
    fi

    INITRD_IMAGE=${@get_image_name(d, 'initrd.img')[1]}
    if [ -n "${INITRD_IMAGE}" ]; then
        sudo cp -f ${IMAGE_ROOTFS}/boot/${@get_image_name(d, 'initrd.img')[0]} ${DEPLOY_DIR_IMAGE}/${INITRD_IMAGE}
    fi
}

addtask copy_boot_files before do_build after do_rootfs
do_copy_boot_files[dirs] = "${DEPLOY_DIR_IMAGE}"
do_copy_boot_files[stamp-extra-info] = "${DISTRO}-${MACHINE}"


SDKCHROOT_DIR = "${TMPDIR}/work/${DISTRO}-${DISTRO_ARCH}/sdkchroot-${HOST_DISTRO}-${HOST_ARCH}/rootfs"

do_populate_sdk() {
    if [ ${HOST_DISTRO} != "debian-stretch" ]; then
         bbfatal "SDK doesn't support ${HOST_DISTRO}"
    fi
    sudo cp -Trpfx ${DEPLOY_DIR_APT}/${HOST_DISTRO}  ${SDKCHROOT_DIR}/isar-apt
}

do_populate_sdk[stamp-extra-info] = "${MACHINE}-${DISTRO}"
do_populate_sdk[depends] = "sdkchroot:do_build"

addtask populate_sdk after do_rootfs
