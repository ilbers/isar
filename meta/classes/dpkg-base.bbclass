# This software is a part of ISAR.
# Copyright (C) 2017-2019 Siemens AG
# Copyright (C) 2019 ilbers GmbH
#
# SPDX-License-Identifier: MIT

inherit sbuild
inherit debianize
inherit terminal
inherit repository
inherit deb-dl-dir

DEPENDS ?= ""
RPROVIDES ?= "${PROVIDES}"

DEPENDS_append_riscv64 = "${@' crossbuild-essential-riscv64' if d.getVar('ISAR_CROSS_COMPILE', True) == '1' and d.getVar('PN') != 'crossbuild-essential-riscv64' else ''}"
DEB_BUILD_PROFILES ?= ""
DEB_BUILD_OPTIONS ?= ""

ISAR_APT_REPO ?= "deb [trusted=yes] file:///home/builder/${PN}/isar-apt/${DISTRO}-${DISTRO_ARCH}/apt/${DISTRO} ${DEBDISTRONAME} main"

python do_adjust_git() {
    import subprocess

    rootdir = d.getVar('WORKDIR', True)

    git_link = os.path.join(d.getVar('GIT_DL_LINK_DIR'), '.git-downloads')
    dl_dir = d.getVar("DL_DIR")
    git_dl = os.path.join(dl_dir, "git")

    if os.path.exists(git_link) and os.path.realpath(git_link) != os.path.realpath(git_dl):
        os.unlink(git_link)

    if not os.path.exists(git_link):
        os.symlink(git_dl, git_link)

    for src_uri in (d.getVar("SRC_URI", True) or "").split():
        try:
            fetcher = bb.fetch2.Fetch([src_uri], d)
            ud = fetcher.ud[src_uri]
            if ud.type != 'git':
                continue

            if os.path.islink(ud.localpath):
                realpath = os.path.realpath(ud.localpath)
                filter_out = git_dl + "/"
                if realpath.startswith(filter_out):
                    # make the link relative
                    link = realpath.replace(filter_out, '', 1)
                    os.unlink(ud.localpath)
                    os.symlink(link, ud.localpath)

            subdir = ud.parm.get("subpath", "")
            if subdir != "":
                def_destsuffix = "%s/" % os.path.basename(subdir.rstrip('/'))
            else:
                def_destsuffix = "git/"

            destsuffix = ud.parm.get("destsuffix", def_destsuffix)
            destdir = ud.destdir = os.path.join(rootdir, destsuffix)

            git_link_rel = os.path.relpath(git_link,
                                           os.path.join(destdir, ".git/objects"))

            alternates = os.path.join(destdir, ".git/objects/info/alternates")

            if os.path.exists(alternates):
                cmd = ["sed", "-i", alternates, "-e",
                       "s|{}|{}|".format(git_dl, git_link_rel)]
                bb.note(' '.join(cmd))
                if subprocess.call(cmd) != 0:
                    bb.fatal("git alternates adjustment failed")
        except bb.fetch2.BBFetchException as e:
            bb.fatal(str(e))
}

addtask adjust_git after do_unpack before do_patch
do_adjust_git[lockfiles] += "${DL_DIR}/git/isar.lock"

inherit patch
addtask patch after do_adjust_git before do_dpkg_build

SRC_APT ?= ""

# filter out all "apt://" URIs out of SRC_URI and stick them into SRC_APT
python() {
    src_uri = (d.getVar('SRC_URI', False) or "").split()

    prefix = "apt://"
    new_src_uri = []
    src_apt = []
    for u in src_uri:
        if u.startswith(prefix):
            src_apt.append(u[len(prefix) :])
        else:
            new_src_uri.append(u)

    d.setVar('SRC_URI', ' '.join(new_src_uri))
    d.prependVar('SRC_APT', ' '.join(src_apt))

    if len(d.getVar('SRC_APT').strip()) > 0:
        bb.build.addtask('apt_unpack', 'do_patch', '', d)
        bb.build.addtask('cleanall_apt', 'do_cleanall', '', d)
}

do_apt_fetch() {
    E="${@ isar_export_proxies(d)}"
    schroot_create_configs

    schroot_cleanup() {
        schroot_delete_configs
    }
    trap 'exit 1' INT HUP QUIT TERM ALRM USR1
    trap 'schroot_cleanup' EXIT

    for uri in "${SRC_APT}"; do
        schroot -d / -c ${SBUILD_CHROOT} -- \
            sh -c 'mkdir -p /downloads/deb-src/"$1"/"$2" && cd /downloads/deb-src/"$1"/"$2" && apt-get -y --download-only --only-source source "$2"' my_script "${BASE_DISTRO}-${BASE_DISTRO_CODENAME}" "${uri}"
    done
    schroot_delete_configs
}

addtask apt_fetch
do_apt_fetch[lockfiles] += "${REPO_ISAR_DIR}/isar.lock"

# Add dependency from the correct schroot: host or target
do_apt_fetch[depends] += "${SCHROOT_DEP}"

do_apt_unpack() {
    rm -rf ${S}
    schroot_create_configs

    schroot_cleanup() {
        schroot_delete_configs
    }
    trap 'exit 1' INT HUP QUIT TERM ALRM USR1
    trap 'schroot_cleanup' EXIT

    for uri in "${SRC_APT}"; do
        schroot -d / -c ${SBUILD_CHROOT} -- \
            sh -c ' \
                set -e
                dscfile="$(apt-get -y -qq --print-uris --only-source source "${2}" | cut -d " " -f2 | grep -E "*.dsc")"
                cd ${PP}
                cp /downloads/deb-src/"${1}"/"${2}"/* ${PP}
                dpkg-source -x "${dscfile}" "${PPS}"' \
                    my_script "${BASE_DISTRO}-${BASE_DISTRO_CODENAME}" "${uri}"
    done
    schroot_delete_configs
}

addtask apt_unpack after do_apt_fetch

do_cleanall_apt[nostamp] = "1"
do_cleanall_apt() {
    for uri in "${SRC_APT}"; do
        rm -rf "${DEBSRCDIR}"/"${DISTRO}"/"$uri"
    done
}

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
do_prepare_build[depends] = "${SCHROOT_DEP}"

do_prepare_build_append() {
    # Make a local copy of isar-apt repo that is not affected by other parallel builds
    mkdir -p ${WORKDIR}/isar-apt/${DISTRO}-${DISTRO_ARCH}
    rm -rf ${WORKDIR}/isar-apt/${DISTRO}-${DISTRO_ARCH}/*
    cp -Rl ${REPO_ISAR_DIR} ${WORKDIR}/isar-apt/${DISTRO}-${DISTRO_ARCH}
}

do_prepare_build[lockfiles] += "${REPO_ISAR_DIR}/isar.lock"

# Placeholder for actual dpkg_runbuild() implementation
dpkg_runbuild() {
    die "This should never be called, overwrite it in your derived class"
}

def isar_deb_build_profiles(d):
    deb_build_profiles = d.getVar('DEB_BUILD_PROFILES', True)
    if d.getVar('ISAR_CROSS_COMPILE', True) == "1":
        deb_build_profiles += ' cross'
    return deb_build_profiles.strip()

def isar_deb_build_options(d):
    deb_build_options = d.getVar('DEB_BUILD_OPTIONS', True)
    return deb_build_options.strip()

# use with caution: might contaminate multiple tasks
def isar_export_build_settings(d):
    import os
    os.environ['DEB_BUILD_OPTIONS']  = isar_deb_build_options(d)
    os.environ['DEB_BUILD_PROFILES'] = isar_deb_build_profiles(d)

python do_dpkg_build() {
    bb.build.exec_func('schroot_create_configs', d)
    try:
        bb.build.exec_func("dpkg_runbuild", d)
    finally:
        bb.build.exec_func('schroot_delete_configs', d)
}

addtask dpkg_build

SSTATETASKS += "do_dpkg_build"
SSTATECREATEFUNCS += "dpkg_build_sstate_prepare"
SSTATEPOSTINSTFUNCS += "dpkg_build_sstate_finalize"

dpkg_build_sstate_prepare() {
    # this runs in SSTATE_BUILDDIR, which will be deleted automatically
    if [ -n "$(find ${WORKDIR} -maxdepth 1 -name '*.deb' -print -quit)" ]; then
        cp -f ${WORKDIR}/*.deb -t .
    fi
}

dpkg_build_sstate_finalize() {
    # this runs in SSTATE_INSTDIR
    if [ -n "$(find . -maxdepth 1 -name '*.deb' -print -quit)" ]; then
        mv -f ./*.deb -t ${WORKDIR}/
    fi
}

python do_dpkg_build_setscene() {
    sstate_setscene(d)
}

addtask dpkg_build_setscene
do_dpkg_build_setscene[dirs] += "${S}/.."

do_dpkg_build[depends] = "${SCHROOT_DEP}"

CLEANFUNCS += "deb_clean"

deb_clean() {
    DEBS=$( find ${WORKDIR} -maxdepth 1 -name "*.deb" || [ ! -d ${S} ] )
    if [ -n "${DEBS}" ]; then
        for d in ${DEBS}; do
            repo_del_package "${REPO_ISAR_DIR}"/"${DISTRO}" \
                "${REPO_ISAR_DB_DIR}"/"${DISTRO}" "${DEBDISTRONAME}" "${d}"
        done
    fi
}
# the clean function modifies isar-apt
do_clean[lockfiles] = "${REPO_ISAR_DIR}/isar.lock"

do_deploy_deb() {
    deb_clean
    repo_add_packages "${REPO_ISAR_DIR}"/"${DISTRO}" \
        "${REPO_ISAR_DB_DIR}"/"${DISTRO}" "${DEBDISTRONAME}" ${WORKDIR}/*.deb
}

addtask deploy_deb after do_dpkg_build before do_build
do_deploy_deb[deptask] = "do_deploy_deb"
do_deploy_deb[rdeptask] = "do_deploy_deb"
do_deploy_deb[depends] += "isar-apt:do_cache_config"
do_deploy_deb[lockfiles] = "${REPO_ISAR_DIR}/isar.lock"
do_deploy_deb[dirs] = "${S}"

python do_devshell() {
    bb.build.exec_func('schroot_create_configs', d)

    isar_export_proxies(d)
    isar_export_ccache(d)
    isar_export_build_settings(d)
    if d.getVar('USE_CCACHE') == '1':
        bb.build.exec_func('schroot_configure_ccache', d)

    schroot = d.getVar('SBUILD_CHROOT')
    isar_apt = d.getVar('ISAR_APT_REPO')
    pkg_arch = d.getVar('PACKAGE_ARCH', True)
    build_arch = d.getVar('SBUILD_HOST_ARCH', True)
    pp_pps = os.path.join(d.getVar('PP'), d.getVar('PPS'))

    install_deps = ":" if d.getVar('BB_CURRENTTASK') == "devshell_nodeps" else f"mk-build-deps -i \
        --host-arch {pkg_arch} --build-arch {build_arch}  \
        -t \"apt-get -y -q -o Debug::pkgProblemResolver=yes --no-install-recommends --allow-downgrades\" \
        debian/control"

    termcmd = "schroot -d / -c {0} -u root -- sh -c ' \
        cd {1}; \
        echo {2} > /etc/apt/sources.list.d/isar_apt.list; \
        apt-get -y -q update; \
        {3}; \
        export PATH=$PATH_PREPEND:$PATH; \
        $SHELL -i \
    '"
    oe_terminal(termcmd.format(schroot, pp_pps, isar_apt, install_deps), "Isar devshell", d)

    bb.build.exec_func('schroot_delete_configs', d)
}

addtask devshell after do_prepare_build
DEVSHELL_STARTDIR ?= "${S}"
do_devshell[dirs] = "${DEVSHELL_STARTDIR}"
do_devshell[nostamp] = "1"

python do_devshell_nodeps() {
    bb.build.exec_func('do_devshell', d)
}

# devshell may be placed after do_instell_builddeps in downstream classes.
# devshell_nodeps will always stay right after do_prepare_build.
addtask devshell_nodeps after do_prepare_build
do_devshell_nodeps[dirs] = "${DEVSHELL_STARTDIR}"
do_devshell_nodeps[nostamp] = "1"
