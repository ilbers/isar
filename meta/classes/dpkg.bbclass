# This software is a part of ISAR.
# Copyright (C) 2015-2018 ilbers GmbH

inherit dpkg-base

# Install build dependencies for package
dpkg_prepare() {
    E="${@ bb.utils.export_proxies(d)}"
    sudo -E chroot ${BUILDCHROOT_DIR} /isar/deps.sh ${PP}/${PPS} ${DISTRO_ARCH}
}

# apt and reprepro may not run in parallel, acquire the Isar lock
do_prepare[lockfiles] += "${DEPLOY_DIR_APT}/isar.lock"

# Build package from sources using build script
dpkg_runbuild() {
    E="${@ bb.utils.export_proxies(d)}"
    sudo -E chroot ${BUILDCHROOT_DIR} /isar/build.sh ${PP}/${PPS} ${DISTRO_ARCH}
}
