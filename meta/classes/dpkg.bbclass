# This software is a part of ISAR.
# Copyright (C) 2015-2016 ilbers GmbH

# Add dependency from buildchroot creation
DEPENDS += "buildchroot"
do_unpack[deptask] = "do_build"

# Each package should have its own unique build folder, so use
# recipe name as identifier
PP = "/home/builder/${PN}"
BUILDROOT = "${BUILDCHROOT_DIR}/${PP}"

addtask fetch
do_fetch[dirs] = "${DL_DIR}"

# Fetch package from the source link
python do_fetch() {
    src_uri = (d.getVar('SRC_URI', True) or "").split()
    if len(src_uri) == 0:
        return

    try:
        fetcher = bb.fetch2.Fetch(src_uri, d)
        fetcher.download()
    except bb.fetch2.BBFetchException as e:
        raise bb.build.FuncFailed(e)
}

addtask fetch before do_build

do_unpack[dirs] = "${BUILDROOT}"
do_unpack[stamp-extra-info] = "${DISTRO}"
S ?= "${BUILDROOT}"

# Unpack package and put it into working directory in buildchroot
python do_unpack() {
    src_uri = (d.getVar('SRC_URI', True) or "").split()
    if len(src_uri) == 0:
        return

    rootdir = d.getVar('BUILDROOT', True)

    try:
        fetcher = bb.fetch2.Fetch(src_uri, d)
        fetcher.unpack(rootdir)
    except bb.fetch2.BBFetchException as e:
        raise bb.build.FuncFailed(e)
}

addtask unpack after do_fetch before do_build

do_build[stamp-extra-info] = "${DISTRO}"

# Build package from sources using build script
do_build() {
    sudo chroot ${BUILDCHROOT_DIR} /build.sh ${PP}/${SRC_DIR}
}

do_install[stamp-extra-info] = "${MACHINE}"

# Install package to dedicated deploy directory
do_install() {
    readonly DIR_CACHE="${APTCACHEDIR}/${DISTRO_NAME}"

    if [ ! -e "${DIR_CACHE}/conf/distributions" ]; then
        mkdir -p "${DIR_CACHE}/conf"
        cat <<EOF >"${DIR_CACHE}/conf/distributions"
Codename: isar
Architectures: i386 armhf source
Components: main
EOF
    fi

    find "${BUILDROOT}" -type f -name \*.deb -exec \
        reprepro -b "${DIR_CACHE}" -C main includedeb isar '{}' +
}

addtask do_install after do_build

python __anonymous () {
    PN = d.getVar("PN", True)
    PV = d.getVar("PV", True)
    DISTRO_ARCH = d.getVar("DISTRO_ARCH", True)
    APTCACHEDIR = d.getVar("APTCACHEDIR", True)
    DISTRO_NAME = d.getVar("DISTRO_NAME", True)
    path_cache = os.path.join(APTCACHEDIR, DISTRO_NAME)
    path_distributions = os.path.join(path_cache, "conf", "distributions")

    if not os.path.exists(path_distributions):
        return

    pd = bb.persist_data.persist("APTCACHE_PACKAGES", d)
    if PN in pd and pd[PN] == PV:
        return

    import subprocess
    try:
        package_version = subprocess.check_output([
            "reprepro", "-b", path_cache,
            "-C", "main",
            "-A", DISTRO_ARCH,
            "--list-format", "${version}",
            "list", "isar", PN,
        ])
        package_version = package_version.decode("utf-8")
        if package_version == PV:
            d.setVarFlag("do_fetch", "noexec", "1")
            d.setVarFlag("do_unpack", "noexec", "1")
            d.setVarFlag("do_build", "noexec", "1")
            d.setVarFlag("do_install", "noexec", "1")
            pd[PN] = PV
    except subprocess.CalledProcessError as e:
        log.msg.error("Unable to check for a candidate for package {0} (errorcode: {1})".format(PN, e.returncode))
}
