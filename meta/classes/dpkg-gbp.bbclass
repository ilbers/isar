# This software is a part of ISAR.
# Copyright (c) Siemens AG, 2019
#
# SPDX-License-Identifier: MIT

inherit dpkg

S = "${WORKDIR}/git"

PATCHTOOL ?= "git"

GBP_DEPENDS ?= "git-buildpackage pristine-tar"
GBP_EXTRA_OPTIONS ?= "--git-pristine-tar"

builddeps_install_append() {
    deb_dl_dir_import "${BUILDCHROOT_DIR}" "${distro}"
    sudo -E chroot ${BUILDCHROOT_DIR} \
        apt-get install -y -o Debug::pkgProblemResolver=yes \
                        --no-install-recommends --download-only ${GBP_DEPENDS}
    deb_dl_dir_export "${BUILDCHROOT_DIR}" "${distro}"
    sudo -E chroot ${BUILDCHROOT_DIR} \
        apt-get install -y -o Debug::pkgProblemResolver=yes \
                        --no-install-recommends ${GBP_DEPENDS}
}

dpkg_runbuild_prepend() {
    export GBP_PREFIX="gbp buildpackage --git-ignore-new ${GBP_EXTRA_OPTIONS} --git-builder="
}
