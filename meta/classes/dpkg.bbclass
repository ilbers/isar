# This software is a part of ISAR.
# Copyright (C) 2015-2018 ilbers GmbH

inherit dpkg-base

# Install build dependencies for package
do_install_builddeps() {
    dpkg_do_mounts
    E="${@ bb.utils.export_proxies(d)}"
    sudo -E chroot ${BUILDCHROOT_DIR} /isar/deps.sh ${PP}/${PPS} ${DISTRO_ARCH}
    dpkg_undo_mounts
}

addtask install_builddeps after do_prepare_build before do_build
# apt and reprepro may not run in parallel, acquire the Isar lock
do_install_builddeps[lockfiles] += "${REPO_ISAR_DIR}/isar.lock"
do_install_builddeps[stamp-extra-info] = "${DISTRO}-${DISTRO_ARCH}"

# Build package from sources using build script
dpkg_runbuild() {
    E="${@ bb.utils.export_proxies(d)}"
    sudo -E chroot --userspec=$( id -u ):$( id -g ) ${BUILDCHROOT_DIR} /isar/build.sh ${PP}/${PPS} ${DISTRO_ARCH}
}
