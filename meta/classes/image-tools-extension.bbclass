# This software is a part of ISAR.
# Copyright (C) Siemens AG, 2019
#
# SPDX-License-Identifier: MIT
#
# This file extends the image.bbclass to supply tools for futher imager functions

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

do_install_imager_deps[depends] = "buildchroot-target:do_build"
do_install_imager_deps[deptask] = "do_deploy_deb"
do_install_imager_deps[lockfiles] += "${REPO_ISAR_DIR}/isar.lock"
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
            --allow-unauthenticated --allow-downgrades install \
            ${IMAGER_INSTALL}'
}
addtask install_imager_deps before do_image_tools
