# This software is a part of ISAR.
# Copyright (C) 2015-2016 ilbers GmbH

inherit dpkg-base

# Build package from sources using build script
dpkg_runbuild() {
    E="${@ bb.utils.export_proxies(d)}"
    sudo -E chroot ${BUILDCHROOT_DIR} /build.sh ${PP}/${S}
}
