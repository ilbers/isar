# This software is a part of ISAR.
# Copyright (C) 2015-2018 ilbers GmbH

inherit dpkg-base

# Install build dependencies for package
do_install_builddeps() {
    dpkg_do_mounts
    E="${@ isar_export_proxies(d)}"
    sudo -E chroot ${BUILDCHROOT_DIR} /isar/deps.sh \
        ${PP}/${PPS} ${DISTRO_ARCH} --download-only
    sudo -E chroot ${BUILDCHROOT_DIR} /isar/deps.sh \
        ${PP}/${PPS} ${DISTRO_ARCH}
    dpkg_undo_mounts
}

addtask install_builddeps after do_prepare_build before do_dpkg_build
# apt and reprepro may not run in parallel, acquire the Isar lock
do_install_builddeps[lockfiles] += "${REPO_ISAR_DIR}/isar.lock"

addtask devshell after do_install_builddeps

# Build package from sources using build script
dpkg_runbuild() {
    E="${@ isar_export_proxies(d)}"
    sudo -E chroot --userspec=$( id -u ):$( id -g ) ${BUILDCHROOT_DIR} \
         /isar/build.sh ${PP}/${PPS} ${DISTRO_ARCH}
}
