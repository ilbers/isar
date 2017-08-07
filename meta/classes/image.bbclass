# This software is a part of ISAR.
# Copyright (C) 2015-2016 ilbers GmbH

KERNEL_IMAGE ?= ""
INITRD_IMAGE ?= ""

IMAGE_INSTALL ?= ""
IMAGE_TYPE    ?= "ext4-img"

inherit ${IMAGE_TYPE}

do_populate[stamp-extra-info] = "${MACHINE}-${DISTRO}"

# Install Debian packages, that were built from sources
do_populate() {
    if [ -n "${IMAGE_INSTALL}" ]; then
        sudo mkdir -p ${S}/deb

        for p in ${IMAGE_INSTALL}; do
            sudo cp ${DEPLOY_DIR_DEB}/${p}_*.deb ${S}/deb
        done

        sudo chroot ${S} /usr/bin/dpkg -i -R /deb

        sudo rm -rf ${S}/deb
    fi
}

addtask populate before do_build
do_populate[deptask] = "do_install"
