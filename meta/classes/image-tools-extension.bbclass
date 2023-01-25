# This software is a part of ISAR.
# Copyright (C) Siemens AG, 2019
#
# SPDX-License-Identifier: MIT
#
# This file extends the image.bbclass to supply tools for futher imager functions

inherit buildchroot

IMAGER_INSTALL ??= ""
IMAGER_BUILD_DEPS ??= ""
DEPENDS += "${IMAGER_BUILD_DEPS}"

do_install_imager_deps[depends] = "${BUILDCHROOT_DEP} isar-apt:do_cache_config"
do_install_imager_deps[deptask] = "do_deploy_deb"
do_install_imager_deps[lockfiles] += "${REPO_ISAR_DIR}/isar.lock"
do_install_imager_deps[network] = "${TASK_USE_NETWORK_AND_SUDO}"
do_install_imager_deps() {
    if [ -z "${@d.getVar("IMAGER_INSTALL", True).strip()}" ]; then
        exit
    fi

    distro="${BASE_DISTRO}-${BASE_DISTRO_CODENAME}"
    if [ ${ISAR_CROSS_COMPILE} -eq 1 ]; then
        distro="${HOST_BASE_DISTRO}-${BASE_DISTRO_CODENAME}"
    fi

    buildchroot_do_mounts

    E="${@ isar_export_proxies(d)}"
    deb_dl_dir_import ${BUILDCHROOT_DIR} ${distro}
    sudo -E chroot ${BUILDCHROOT_DIR} sh -c ' \
        apt-get update \
            -o Dir::Etc::SourceList="sources.list.d/isar-apt.list" \
            -o Dir::Etc::SourceParts="-" \
            -o APT::Get::List-Cleanup="0"
        apt-get -o Debug::pkgProblemResolver=yes --no-install-recommends -y \
            --allow-unauthenticated --allow-downgrades --download-only install \
            ${IMAGER_INSTALL}'

    deb_dl_dir_export ${BUILDCHROOT_DIR} ${distro}
    sudo -E chroot ${BUILDCHROOT_DIR} sh -c ' \
        apt-get -o Debug::pkgProblemResolver=yes --no-install-recommends -y \
            --allow-unauthenticated --allow-downgrades install \
            ${IMAGER_INSTALL}'
}
addtask install_imager_deps before do_image_tools
