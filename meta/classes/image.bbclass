# This software is a part of ISAR.
# Copyright (C) 2015-2016 ilbers GmbH

KERNEL_IMAGE ?= ""
INITRD_IMAGE ?= ""

IMAGE_INSTALL ?= ""
IMAGE_TYPE    ?= "ext4-img"
IMAGE_ROOTFS   = "${WORKDIR}/rootfs"

inherit ${IMAGE_TYPE}

do_populate[stamp-extra-info] = "${MACHINE}-${DISTRO}"

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
do_populate[deptask] = "do_install"
