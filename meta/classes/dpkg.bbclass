# This software is a part of ISAR.
# Copyright (C) 2015-2016 ilbers GmbH

inherit isar-base

# Add dependency from buildchroot creation
DEPENDS += "buildchroot"
do_unpack[deptask] = "do_build"

# Each package should have its own unique build folder, so use
# recipe name as identifier
PP = "/home/builder/${PN}"
WORKDIR = "${BUILDCHROOT_DIR}/${PP}"
S ?= "${WORKDIR}"

do_build[stamp-extra-info] = "${DISTRO}"

# Build package from sources using build script
do_build() {
    sudo chroot ${BUILDCHROOT_DIR} /build.sh ${PP}/${SRC_DIR}
}

do_install[stamp-extra-info] = "${MACHINE}"

# Install package to dedicated deploy directory
do_install() {
    install -m 755 ${WORKDIR}/*.deb ${DEPLOY_DIR_DEB}/
}

addtask do_install after do_build
do_install[dirs] = "${DEPLOY_DIR_DEB}"
