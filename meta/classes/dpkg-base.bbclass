# This software is a part of ISAR.
# Copyright (C) 2017 Siemens AG

# Add dependency from buildchroot creation
do_build[depends] = "buildchroot:do_setup_mounts"

# Add dependency between Isar recipes
DEPENDS ?= ""
do_build[deptask] = "do_deploy_deb"

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

    sudo umount ${BUILDROOT} 2>/dev/null || true
    sudo rmdir ${BUILDROOT} 2>/dev/null || true
}

# Install package to Isar-apt
do_deploy_deb() {
    reprepro -b ${DEPLOY_DIR_APT}/${DISTRO} \
             --dbdir ${DEPLOY_DIR_DB}/${DISTRO} \
             -C main \
             includedeb ${DEBDISTRONAME} \
             ${WORKDIR}/*.deb
}

addtask deploy_deb after do_build
do_deploy_deb[dirs] = "${DEPLOY_DIR_DEB}"
do_deploy_deb[stamp-extra-info] = "${DISTRO}-${MACHINE}"
do_deploy_deb[lockfiles] = "${DEPLOY_DIR_APT}/isar.lock"
do_deploy_deb[depends] = "isar-apt:do_cache_config"
