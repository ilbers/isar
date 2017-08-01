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

# Build package from sources using build script
do_compile() {
    sudo chroot ${BUILDCHROOT_DIR} /build.sh ${PP}/${SRC_DIR}
}

addtask compile after do_unpack before do_install
do_compile[stamp-extra-info] = "${DISTRO}"

# Install package to dedicated deploy directory
do_install() {
    install -m 755 ${WORKDIR}/*.deb ${DEPLOY_DIR_DEB}/
}

addtask install after do_compile before do_build
do_install[dirs] = "${DEPLOY_DIR_DEB}"
do_install[stamp-extra-info] = "${MACHINE}"
