# This software is a part of ISAR.
# Copyright (C) 2015-2016 ilbers GmbH

inherit dpkg-base

# Add dependency from buildchroot creation
DEPENDS += "buildchroot"
do_build[deptask] = "do_build"

# Each package should have its own unique build folder, so use
# recipe name as identifier
PP = "/home/builder/${PN}"

BUILDROOT = "${BUILDCHROOT_DIR}/${PP}"
do_build[stamp-extra-info] = "${DISTRO}-${DISTRO_ARCH}"

# Build package from sources using build script
dpkg_runbuild() {
    sudo chroot ${BUILDCHROOT_DIR} /build.sh ${PP}/${SRC_DIR}
}

# Wrap the function dpkg_runbuild with the bind mount for buildroot
do_build() {
    mkdir -p ${BUILDROOT}
    sudo mount --bind ${WORKDIR} ${BUILDROOT}
    dpkg_runbuild
    sudo umount ${BUILDROOT}
    rm -rf ${BUILDROOT}
}
