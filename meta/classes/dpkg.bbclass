# This software is a part of ISAR.
# Copyright (C) 2015-2016 ilbers GmbH

# Add dependency from buildchroot creation
DEPENDS += "buildchroot"
do_unpack[deptask] = "do_build"

# Each package should have its own unique build folder, so use
# recipe name as identifier
PP = "/home/builder/${PN}"
BUILDROOT = "${BUILDCHROOT_DIR}/${PP}"

do_unpack[dirs] = "${BUILDROOT}"
do_unpack[stamp-extra-info] = "${DISTRO}-${DISTRO_ARCH}"
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

do_build[stamp-extra-info] = "${DISTRO}-${DISTRO_ARCH}"

# Build package from sources using build script
do_build() {
    sudo chroot ${BUILDCHROOT_DIR} /build.sh ${PP}/${SRC_DIR}
}


# Install package to dedicated deploy directory
do_install() {
    install -m 644 ${BUILDROOT}/*.deb ${DEPLOY_DIR_DEB}/
}

addtask install after do_build
do_install[dirs] = "${DEPLOY_DIR_DEB}"
do_install[stamp-extra-info] = "${MACHINE}"
