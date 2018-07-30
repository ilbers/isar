# This software is a part of ISAR.
# Copyright (C) 2015-2018 ilbers GmbH

inherit dpkg-base

BUILDCHROOT_DIR = "${BUILDCHROOT_TARGET_DIR}"

# Build package from sources using build script
dpkg_runbuild() {
    E="${@ bb.utils.export_proxies(d)}"
    sudo -E chroot ${BUILDCHROOT_DIR} /build.sh ${PP}/${PPS}
}
