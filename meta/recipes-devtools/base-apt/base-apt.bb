# This software is a part of ISAR.
# Copyright (C) 2018 ilbers GmbH
# Copyright (C) 2020 Siemens AG
#
# SPDX-License-Identifier: MIT

inherit repository

BASE_REPO_KEY ?= ""
KEYFILES ?= ""

do_cache_config[stamp-extra-info] = "${DISTRO}"
do_cache_config[lockfiles] = "${REPO_BASE_DIR}/isar.lock"

# Generate reprepro config for current distro if it doesn't exist. Once it's
# generated, this task should do nothing.
repo_config() {
    repo_create "${REPO_BASE_DIR}"/"${BASE_DISTRO}" \
        "${REPO_BASE_DB_DIR}"/"${BASE_DISTRO}" \
        "${BASE_DISTRO_CODENAME}" \
        "${KEYFILES}"
}

python do_cache_config() {
    for key in d.getVar('BASE_REPO_KEY').split():
        d.appendVar("SRC_URI", " %s" % key)
        fetcher = bb.fetch2.Fetch([key], d)
        filename = fetcher.localpath(key)
        d.appendVar("KEYFILES", " %s" % filename)

    bb.build.exec_func('repo_config', d)
}

addtask cache_config after do_unpack before do_build
