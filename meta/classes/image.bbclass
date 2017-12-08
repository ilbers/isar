# This software is a part of ISAR.
# Copyright (C) 2015-2017 ilbers GmbH

IMAGE_INSTALL ?= ""
IMAGE_TYPE    ?= "ext4-img"
IMAGE_ROOTFS   = "${WORKDIR}/rootfs"

def get_image_name(d, name_link):
    S = d.getVar("IMAGE_ROOTFS", True)
    path_link = os.path.join(S, name_link)
    if os.path.lexists(path_link):
        return os.path.basename(os.path.realpath(path_link))
    return ""

# These variables are used by wic and start_vm
KERNEL_IMAGE ?= "${@get_image_name(d, 'vmlinuz')}"
INITRD_IMAGE ?= "${@get_image_name(d, 'initrd.img')}"

inherit ${IMAGE_TYPE}
call_reprepro() {
    for i in $(seq 1 ${REPREPRO_LOCK_ATTEMPTS}); do
        #  According to `sh` manual page, shell exit statuses fall between
        # 0-255. The EEXIST error code is (-17), so casting to usigned 8-bit
        # integer results value (239).
        eexist=$(python -c 'import errno; print(256-errno.EEXIST)')
        retval="0"
        reprepro $* || retval="$?"

        # If reprepro has failed to get database lock, it returns EEXIST code.
        # In this case we continue trying to get lock until max amount of
        # attempts is reached.
        if [ $retval -eq $eexist ]; then
            bbwarn "Failed to get reprepro lock, trying again..."
            sleep 5
        else
            break
        fi
    done

    if [ $retval -ne 0 ]; then
        bbfatal "reprepro failed"
    fi
}

CACHE_CONF_DIR = "${DEPLOY_DIR_APT}/${DISTRO}/conf"
do_cache_config[dirs] = "${CACHE_CONF_DIR}"
do_cache_config[stamp-extra-info] = "${DISTRO}"

# Generate reprepro config for current distro if it doesn't exist. Once it's
# generated, this task should do nothing.
do_cache_config() {
    if [ ! -e "${CACHE_CONF_DIR}/distributions" ]; then
        sed -e "s#{DISTRO_NAME}#"${DEBDISTRONAME}"#g" \
            ${FILESDIR}/distributions.in > ${CACHE_CONF_DIR}/distributions
    fi

    path_cache="${DEPLOY_DIR_APT}/${DISTRO}"
    path_databases="${DEPLOY_DIR_DB}/${DISTRO}"

    if [ ! -d "${path_databases}" ]; then
        call_reprepro -b ${path_cache} \
                      --dbdir ${path_databases} \
                      export ${DEBDISTRONAME}
    fi
}

addtask cache_config before do_populate

do_populate[stamp-extra-info] = "${DISTRO}-${MACHINE}"

# Populate Isar apt repository by newly built packages
do_populate() {
    if [ -n "${IMAGE_INSTALL}" ]; then
        call_reprepro -b ${DEPLOY_DIR_APT}/${DISTRO} \
                      --dbdir ${DEPLOY_DIR_DB}/${DISTRO} \
                      -C main \
                      includedeb ${DEBDISTRONAME} \
                      ${DEPLOY_DIR_DEB}/*.deb
    fi
}

addtask populate before do_build after do_unpack
do_populate[deptask] = "do_deploy_deb"

do_rootfs[stamp-extra-info] = "${MACHINE}-${DISTRO}"

do_rootfs() {
    die "No root filesystem function defined, please implement in your recipe"
}

addtask rootfs before do_build after do_populate

do_copy_boot_files() {
    KERNEL_IMAGE=${@get_image_name(d, 'vmlinuz')}
    if [ -n "${KERNEL_IMAGE}" ]; then
        cp -f ${IMAGE_ROOTFS}/boot/${KERNEL_IMAGE} ${DEPLOY_DIR_IMAGE}
    fi

    INITRD_IMAGE=${@get_image_name(d, 'initrd.img')}
    if [ -n "${INITRD_IMAGE}" ]; then
        sudo cp -f ${IMAGE_ROOTFS}/boot/${INITRD_IMAGE} ${DEPLOY_DIR_IMAGE}
    fi
}

addtask copy_boot_files before do_build after do_rootfs
do_copy_boot_files[dirs] = "${DEPLOY_DIR_IMAGE}"
do_copy_boot_files[stamp-extra-info] = "${DISTRO}-${MACHINE}"
