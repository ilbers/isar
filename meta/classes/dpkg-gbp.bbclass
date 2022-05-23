# This software is a part of ISAR.
# Copyright (c) Siemens AG, 2019
#
# SPDX-License-Identifier: MIT

inherit dpkg

S = "${WORKDIR}/git"

PATCHTOOL ?= "git"

GBP_DEPENDS ?= "git-buildpackage pristine-tar"
GBP_EXTRA_OPTIONS ?= "--git-pristine-tar"

do_install_builddeps_append() {
    dpkg_do_mounts
    distro="${DISTRO}"
    if [ ${ISAR_CROSS_COMPILE} -eq 1 ]; then
       distro="${HOST_DISTRO}"
    fi
    deb_dl_dir_import "${BUILDCHROOT_DIR}" "${distro}"
    sudo -E chroot ${BUILDCHROOT_DIR} \
        apt-get install -y -o Debug::pkgProblemResolver=yes \
                        --no-install-recommends --download-only ${GBP_DEPENDS}
    deb_dl_dir_export "${BUILDCHROOT_DIR}" "${distro}"
    sudo -E chroot ${BUILDCHROOT_DIR} \
        apt-get install -y -o Debug::pkgProblemResolver=yes \
                        --no-install-recommends ${GBP_DEPENDS}
    dpkg_undo_mounts
}

dpkg_runbuild_prepend() {
    sudo -E chroot --userspec=$( id -u ):$( id -g ) ${BUILDCHROOT_DIR} \
        sh -c "cd ${PP}/${PPS} && gbp buildpackage --git-ignore-new --git-builder=/bin/true ${GBP_EXTRA_OPTIONS}"
    # NOTE: `buildpackage --git-builder=/bin/true --git-pristine-tar` is used
    # for compatibility with gbp version froms debian-stretch. In newer distros
    # it's possible to use a subcommand `export-orig --pristine-tar`
}
