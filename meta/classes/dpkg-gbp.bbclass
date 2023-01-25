# This software is a part of ISAR.
# Copyright (c) Siemens AG, 2019
#
# SPDX-License-Identifier: MIT

inherit dpkg

S = "${WORKDIR}/git"

PATCHTOOL ?= "git"

GBP_EXTRA_OPTIONS ?= "--git-pristine-tar"

SCHROOT_MOUNTS = "${WORKDIR}:${PP} ${GITDIR}:/home/.git-downloads"

dpkg_runbuild:prepend() {
    sh -c "
        cd ${WORKDIR}/${PPS}
        gbp buildpackage --git-ignore-new --git-builder=/bin/true ${GBP_EXTRA_OPTIONS}
    "
}
