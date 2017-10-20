# This software is a part of ISAR.
# Copyright (C) 2017 Siemens AG

# Add dependency from buildchroot creation
DEPENDS += "buildchroot"
do_build[deptask] = "do_build"

# Each package should have its own unique build folder, so use
# recipe name as identifier
PP = "/home/builder/${PN}"

BUILDROOT = "${BUILDCHROOT_DIR}/${PP}"
do_build[stamp-extra-info] = "${DISTRO}-${DISTRO_ARCH}"

# default to "emtpy" implementation
dpkg_runbuild() {
    die "This should never be called, overwrite it in your derived class"
}

# Wrap the function dpkg_runbuild with the bind mount for buildroot
do_build() {
    mkdir -p ${BUILDROOT}
    sudo mount --bind ${WORKDIR} ${BUILDROOT}
    dpkg_runbuild
    sudo umount ${BUILDROOT}
    rm -rf ${BUILDROOT}
}

# Install package to dedicated deploy directory
do_deploy_deb() {
    install -m 644 ${WORKDIR}/*.deb ${DEPLOY_DIR_DEB}/
}

addtask deploy_deb after do_build
do_deploy_deb[dirs] = "${DEPLOY_DIR_DEB}"
do_deploy_deb[stamp-extra-info] = "${MACHINE}"
