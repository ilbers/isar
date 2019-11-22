# This software is a part of ISAR.
# Copyright (C) 2017-2019 Siemens AG
# Copyright (C) 2019 ilbers GmbH
#
# SPDX-License-Identifier: MIT

inherit buildchroot
inherit debianize
inherit terminal

DEPENDS ?= ""

python do_adjust_git() {
    import subprocess

    rootdir = d.getVar('WORKDIR', True)

    for src_uri in (d.getVar("SRC_URI", True) or "").split():
        try:
            fetcher = bb.fetch2.Fetch([src_uri], d)
            ud = fetcher.ud[src_uri]
            if ud.type != 'git':
                continue

            subdir = ud.parm.get("subpath", "")
            if subdir != "":
                def_destsuffix = "%s/" % os.path.basename(subdir.rstrip('/'))
            else:
                def_destsuffix = "git/"

            destsuffix = ud.parm.get("destsuffix", def_destsuffix)
            destdir = ud.destdir = os.path.join(rootdir, destsuffix)

            alternates = os.path.join(destdir, ".git/objects/info/alternates")

            if os.path.exists(alternates):
                cmd = ["sed", "-i", alternates, "-e",
                       "s|{}|/downloads|".format(d.getVar("DL_DIR"))]
                bb.note(' '.join(cmd))
                if subprocess.call(cmd) != 0:
                    bb.fatal("git alternates adjustment failed")
        except bb.fetch2.BBFetchException as e:
            raise bb.build.FuncFailed(e)
}

addtask adjust_git after do_unpack before do_patch

inherit patch
addtask patch after do_adjust_git before do_dpkg_build

SRC_APT ?= ""

do_apt_fetch() {
    if [ -z "${@d.getVar("SRC_APT", True).strip()}" ]; then
        exit
    fi
    rm -rf ${S}
    dpkg_do_mounts
    E="${@ isar_export_proxies(d)}"
    sudo -E chroot ${BUILDCHROOT_DIR} /usr/bin/apt-get update \
        -o Dir::Etc::SourceList="sources.list.d/isar-apt.list" \
        -o Dir::Etc::SourceParts="-" \
        -o APT::Get::List-Cleanup="0"

    sudo -E chroot --userspec=$( id -u ):$( id -g ) ${BUILDCHROOT_DIR} \
        sh -c 'cd ${PP} && apt-get -y --only-source source ${SRC_APT}'
    dpkg_undo_mounts
}

addtask apt_fetch after do_unpack before do_patch
do_apt_fetch[lockfiles] += "${REPO_ISAR_DIR}/isar.lock"

def get_package_srcdir(d):
    s = os.path.abspath(d.getVar("S", True))
    workdir = os.path.abspath(d.getVar("WORKDIR", True))
    if os.path.commonpath([s, workdir]) == workdir:
        if s == workdir:
            bb.warn('S is not a subdir of WORKDIR debian package operations' +
                    ' will not work for this recipe.')
        return s[len(workdir)+1:]
    bb.warn('S does not start with WORKDIR')
    return s

# Each package should have its own unique build folder, so use
# recipe name as identifier
PP = "/home/builder/${PN}"
PPS ?= "${@get_package_srcdir(d)}"

# Empty do_prepare_build() implementation, to be overwritten if needed
do_prepare_build() {
    true
}

addtask prepare_build after do_patch do_transform_template before do_dpkg_build
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
    i=1
    while ! sudo umount ${BUILDROOT}; do
        sleep 0.1
        i=`expr $i + 1`
        if [ $i -gt 100 ]; then
            bbwarn "${BUILDROOT}: Couldn't unmount, retrying..."
            i=1
        fi
    done
    sudo rmdir ${BUILDROOT}
}

# Placeholder for actual dpkg_runbuild() implementation
dpkg_runbuild() {
    die "This should never be called, overwrite it in your derived class"
}

python do_dpkg_build() {
    lock = bb.utils.lockfile(d.getVar("REPO_ISAR_DIR") + "/isar.lock",
                             shared=True)
    bb.build.exec_func("dpkg_do_mounts", d)
    bb.build.exec_func("dpkg_runbuild", d)
    bb.build.exec_func("dpkg_undo_mounts", d)
    bb.utils.unlockfile(lock)
}

addtask dpkg_build before do_build

CLEANFUNCS += "repo_clean"

repo_clean() {
    DEBS=$( find ${S}/.. -maxdepth 1 -name "*.deb" || [ ! -d ${S} ] )
    if [ -n "${DEBS}" ]; then
        for d in ${DEBS}; do
            p=$( dpkg-deb --show --showformat '${Package}' ${d} )
            a=$( dpkg-deb --show --showformat '${Architecture}' ${d} )
            # removing "all" means no arch
            aarg="-A ${a}"
            [ "${a}" = "all" ] && aarg=""
            reprepro -b ${REPO_ISAR_DIR}/${DISTRO} \
                     --dbdir ${REPO_ISAR_DB_DIR}/${DISTRO} \
                     -C main ${aarg} \
                     remove ${DEBDISTRONAME} \
                     ${p}
        done
    fi
}

# Install package to Isar-apt
do_deploy_deb() {
    if [ -n "${GNUPGHOME}" ]; then
        export GNUPGHOME="${GNUPGHOME}"
    fi
    repo_clean
    reprepro -b ${REPO_ISAR_DIR}/${DISTRO} \
             --dbdir ${REPO_ISAR_DB_DIR}/${DISTRO} \
             -C main \
             includedeb ${DEBDISTRONAME} \
             ${S}/../*.deb
}

addtask deploy_deb after do_dpkg_build before do_build
do_deploy_deb[lockfiles] = "${REPO_ISAR_DIR}/isar.lock"
do_deploy_deb[depends] = "isar-apt:do_cache_config"
do_deploy_deb[dirs] = "${S}"

python do_devshell() {
    import sys

    oe_lib_path = os.path.join(d.getVar('LAYERDIR_core'), 'lib')
    sys.path.insert(0, oe_lib_path)

    bb.build.exec_func('dpkg_do_mounts', d)

    isar_export_proxies(d)

    buildchroot = d.getVar('BUILDCHROOT_DIR')
    pp_pps = os.path.join(d.getVar('PP'), d.getVar('PPS'))
    termcmd = "sudo -E chroot {0} sh -c 'cd {1}; $SHELL -i'"
    oe_terminal(termcmd.format(buildchroot, pp_pps), "Isar devshell", d)

    bb.build.exec_func('dpkg_undo_mounts', d)
}

addtask devshell after do_prepare_build
DEVSHELL_STARTDIR ?= "${S}"
do_devshell[dirs] = "${DEVSHELL_STARTDIR}"
do_devshell[nostamp] = "1"
