# This software is a part of ISAR.
# Copyright (C) 2017-2018 Siemens AG
#
# SPDX-License-Identifier: MIT

inherit buildchroot

DEPENDS ?= ""

do_adjust_git() {
    if [ -f ${S}/.git/objects/info/alternates ]; then
        sed -i ${S}/.git/objects/info/alternates \
            -e 's|${DL_DIR}|/downloads|'
    fi
}

addtask adjust_git after do_unpack before do_patch
do_adjust_git[stamp-extra-info] = "${DISTRO}-${DISTRO_ARCH}"

inherit patch
addtask patch after do_adjust_git before do_build

def get_package_srcdir(d):
    s = d.getVar("S", True)
    workdir = d.getVar("WORKDIR", True)
    if s.startswith(workdir):
        return s[len(workdir)+1:]
    bb.warn('S does not start with WORKDIR')
    return s

# Each package should have its own unique build folder, so use
# recipe name as identifier
PP = "/home/builder/${PN}"
PPS ?= "${@get_package_srcdir(d)}"

do_build[stamp-extra-info] = "${DISTRO}-${DISTRO_ARCH}"

# Empty do_prepare_build() implementation, to be overwritten if needed
do_prepare_build() {
    true
}

addtask prepare_build after do_patch before do_build
do_prepare_build[stamp-extra-info] = "${DISTRO}-${DISTRO_ARCH}"
# If Isar recipes depend on each other, they typically need the package
# deployed to isar-apt
do_prepare_build[deptask] = "do_deploy_deb"

BUILDROOT = "${BUILDCHROOT_DIR}/${PP}"

dpkg_do_mounts() {
    mkdir -p ${BUILDROOT}
    sudo mount --bind ${WORKDIR} ${BUILDROOT}

    buildchroot_do_mounts
}

dpkg_undo_mounts() {
    sudo umount ${BUILDROOT} 2>/dev/null || true
    sudo rmdir ${BUILDROOT} 2>/dev/null || true
}

# Placeholder for actual dpkg_runbuild() implementation
dpkg_runbuild() {
    die "This should never be called, overwrite it in your derived class"
}

do_build() {
    dpkg_do_mounts
    dpkg_runbuild
    dpkg_undo_mounts
}

CLEANFUNCS += "repo_clean"

repo_clean() {
    PACKAGES=$(cd ${S}/..; ls *.deb | sed 's/\([^_]*\).*/\1/')
    if [ -n "${PACKAGES}" ]; then
        reprepro -b ${REPO_ISAR_DIR}/${DISTRO} \
                 --dbdir ${REPO_ISAR_DB_DIR}/${DISTRO} \
                 -C main -A ${DISTRO_ARCH} \
                 remove ${DEBDISTRONAME} \
                 ${PACKAGES}
    fi
}

# Install package to Isar-apt
do_deploy_deb() {
    repo_clean
    reprepro -b ${REPO_ISAR_DIR}/${DISTRO} \
             --dbdir ${REPO_ISAR_DB_DIR}/${DISTRO} \
             -C main \
             includedeb ${DEBDISTRONAME} \
             ${S}/../*.deb
}

addtask deploy_deb after do_build
do_deploy_deb[stamp-extra-info] = "${DISTRO}-${DISTRO_ARCH}"
do_deploy_deb[lockfiles] = "${REPO_ISAR_DIR}/isar.lock"
do_deploy_deb[depends] = "isar-apt:do_cache_config"
do_deploy_deb[dirs] = "${S}"
