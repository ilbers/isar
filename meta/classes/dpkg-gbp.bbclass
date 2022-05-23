# This software is a part of ISAR.
# Copyright (c) Siemens AG, 2019
#
# SPDX-License-Identifier: MIT

inherit dpkg

S = "${WORKDIR}/git"

PATCHTOOL ?= "git"

GBP_EXTRA_OPTIONS ?= "--git-pristine-tar"

SCHROOT_MOUNTS = "${WORKDIR}:${PP} ${GITDIR}:/home/.git-downloads"

dpkg_runbuild_prepend() {
    sh -c "
        cd ${WORKDIR}/${PPS}
        gbp buildpackage --git-ignore-new --git-builder=/bin/true ${GBP_EXTRA_OPTIONS}
    "
    # NOTE: `buildpackage --git-builder=/bin/true --git-pristine-tar` is used
    # for compatibility with gbp version froms debian-stretch. In newer distros
    # it's possible to use a subcommand `export-orig --pristine-tar`
}
