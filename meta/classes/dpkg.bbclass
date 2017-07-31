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
do_fetch[dirs] = "${DL_DIR}"

do_unpack[stamp-extra-info] = "${DISTRO}"
S ?= "${WORKDIR}"

# Unpack package and put it into working directory in buildchroot
python do_unpack() {
    src_uri = (d.getVar('SRC_URI', True) or "").split()
    if len(src_uri) == 0:
        return

    try:
        fetcher = bb.fetch2.Fetch(src_uri, d)
        fetcher.unpack(d.getVar('WORKDIR', True))
    except bb.fetch2.BBFetchException as e:
        raise bb.build.FuncFailed(e)
}

addtask unpack after do_fetch before do_build
do_unpack[dirs] = "${WORKDIR}"

do_build[stamp-extra-info] = "${DISTRO}"

# Build package from sources using build script
do_build() {
    sudo chroot ${BUILDCHROOT_DIR} /build.sh ${PP}/${SRC_DIR}
}

do_install[stamp-extra-info] = "${MACHINE}"

# Install package to dedicated deploy directory
do_install() {
    install -d ${DEPLOY_DIR_DEB}
    install -m 755 ${WORKDIR}/*.deb ${DEPLOY_DIR_DEB}/
}

addtask do_install after do_build
