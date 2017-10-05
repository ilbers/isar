# This software is a part of ISAR.
# Copyright (C) 2015-2017 ilbers GmbH

KERNEL_IMAGE ?= ""
INITRD_IMAGE ?= ""

IMAGE_INSTALL ?= ""
IMAGE_TYPE    ?= "ext4-img"
IMAGE_ROOTFS   = "${WORKDIR}/rootfs"

inherit ${IMAGE_TYPE}

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
}

addtask cache_config before do_fetch

do_populate[stamp-extra-info] = "${DISTRO}-${MACHINE}"

# Install Debian packages, that were built from sources
do_populate() {
    if [ -n "${IMAGE_INSTALL}" ]; then
        sudo mkdir -p ${IMAGE_ROOTFS}/deb

        for p in ${IMAGE_INSTALL}; do
            sudo cp ${DEPLOY_DIR_DEB}/${p}_*.deb ${IMAGE_ROOTFS}/deb
        done

        sudo chroot ${IMAGE_ROOTFS} /usr/bin/dpkg -i -R /deb

        sudo rm -rf ${IMAGE_ROOTFS}/deb
    fi
}

addtask populate before do_build
do_populate[deptask] = "do_deploy_deb"
