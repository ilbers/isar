# This software is a part of ISAR.
# Copyright (C) 2015-2017 ilbers GmbH
# Copyright (C) 2020 Siemens AG
#
# SPDX-License-Identifier: MIT

inherit repository

SRC_URI = "file://distributions.in"

do_cache_config[lockfiles] = "${REPO_ISAR_DIR}/isar.lock"

# Generate reprepro config for current distro if it doesn't exist. Once it's
# generated, this task should do nothing.
do_cache_config() {
    repo_create "${REPO_ISAR_DIR}"/"${DISTRO}" \
        "${REPO_ISAR_DB_DIR}"/"${DISTRO}" \
        "${DEBDISTRONAME}" \
        "${WORKDIR}/distributions.in"
}

addtask cache_config after do_unpack before do_build
