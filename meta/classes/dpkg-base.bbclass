# This software is a part of ISAR.
# Copyright (C) 2017 Siemens AG

ISAR_CROSS_COMPILE ??= "0"

# Add dependency from the correct buildchroot: host or target
python __anonymous() {
    mode = d.getVar('ISAR_CROSS_COMPILE', True)
    if mode == "0":
        dep = "buildchroot-target:do_build"
        rootfs = d.getVar('BUILDCHROOT_TARGET_DIR', True)
    else:
        dep = "buildchroot-host:do_build"
        rootfs = d.getVar('BUILDCHROOT_HOST_DIR', True)

    d.setVarFlag('do_build', 'depends', dep)
    d.setVar('BUILDCHROOT_DIR', rootfs)
}

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

# Add dependency between Isar recipes
DEPENDS ?= ""
do_build[deptask] = "do_deploy_deb"

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

BUILDROOT = "${BUILDCHROOT_DIR}/${PP}"
do_build[stamp-extra-info] = "${DISTRO}-${DISTRO_ARCH}"

# default to "emtpy" implementation
dpkg_runbuild() {
    die "This should never be called, overwrite it in your derived class"
}

MOUNT_LOCKFILE = "${BUILDCHROOT_DIR}/mount.lock"

# Wrap the function dpkg_runbuild with the bind mount for buildroot
do_build() {
    mkdir -p ${BUILDROOT}
    sudo mount --bind ${WORKDIR} ${BUILDROOT}

    sudo flock ${MOUNT_LOCKFILE} -c ' \
        set -e
        if ! grep -q ${BUILDCHROOT_DIR}/isar-apt /proc/mounts; then \
            mount --bind ${DEPLOY_DIR_APT}/${DISTRO} ${BUILDCHROOT_DIR}/isar-apt; \
            mount --bind ${DL_DIR} ${BUILDCHROOT_DIR}/downloads; \
            mount -t devtmpfs -o mode=0755,nosuid devtmpfs ${BUILDCHROOT_DIR}/dev; \
            mount -t proc none ${BUILDCHROOT_DIR}/proc; \
        fi'

    dpkg_runbuild

    sudo umount ${BUILDROOT} 2>/dev/null || true
    sudo rmdir ${BUILDROOT} 2>/dev/null || true
}

CLEANFUNCS += "repo_clean"

repo_clean() {
    PACKAGES=$(cd ${S}/..; ls *.deb | sed 's/\([^_]*\).*/\1/')
    if [ -n "${PACKAGES}" ]; then
        reprepro -b ${DEPLOY_DIR_APT}/${DISTRO} \
                 --dbdir ${DEPLOY_DIR_DB}/${DISTRO} \
                 -C main -A ${DISTRO_ARCH} \
                 remove ${DEBDISTRONAME} \
                 ${PACKAGES}
    fi
}

# Install package to Isar-apt
do_deploy_deb() {
    repo_clean
    reprepro -b ${DEPLOY_DIR_APT}/${DISTRO} \
             --dbdir ${DEPLOY_DIR_DB}/${DISTRO} \
             -C main \
             includedeb ${DEBDISTRONAME} \
             ${S}/../*.deb
}

addtask deploy_deb after do_build
do_deploy_deb[stamp-extra-info] = "${DISTRO}-${DISTRO_ARCH}"
do_deploy_deb[lockfiles] = "${DEPLOY_DIR_APT}/isar.lock"
do_deploy_deb[depends] = "isar-apt:do_cache_config"
do_deploy_deb[dirs] = "${S}"
