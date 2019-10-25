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

do_install_imager_deps[depends] = "buildchroot-target:do_build"
do_install_imager_deps[deptask] = "do_deploy_deb"
do_install_imager_deps[lockfiles] += "${REPO_ISAR_DIR}/isar.lock"
do_install_imager_deps() {
    if [ -z "${@d.getVar("IMAGER_INSTALL", True).strip()}" ]; then
        exit
    fi

    buildchroot_do_mounts

    E="${@ isar_export_proxies(d)}"
    deb_dl_dir_import ${BUILDCHROOT_DIR}
    sudo -E chroot ${BUILDCHROOT_DIR} sh -c ' \
        apt-get update \
            -o Dir::Etc::SourceList="sources.list.d/isar-apt.list" \
            -o Dir::Etc::SourceParts="-" \
            -o APT::Get::List-Cleanup="0"
        apt-get -o Debug::pkgProblemResolver=yes --no-install-recommends -y \
            --allow-unauthenticated --allow-downgrades --download-only install \
            ${IMAGER_INSTALL}'

    deb_dl_dir_export ${BUILDCHROOT_DIR}
    sudo -E chroot ${BUILDCHROOT_DIR} sh -c ' \
        apt-get -o Debug::pkgProblemResolver=yes --no-install-recommends -y \
            --allow-unauthenticated --allow-downgrades install \
            ${IMAGER_INSTALL}'
}
addtask install_imager_deps before do_image_tools
