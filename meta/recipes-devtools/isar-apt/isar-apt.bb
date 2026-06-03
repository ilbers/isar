# This software is a part of Isar.
# Copyright (C) 2015-2017 ilbers GmbH
# Copyright (C) 2020 Siemens AG
#
# SPDX-License-Identifier: MIT

inherit repository

SRC_URI = "file://distributions.in"

do_cache_config[lockfiles] = "${REPO_ISAR_DIR}/isar.lock"
do_cache_config[vardeps] += "ISAR_APT_OPT_FIELD"

# Generate reprepro config for current distro if it doesn't exist. Once it's
# generated, this task should do nothing.
do_cache_config() {
    # this part must be executed while holding the isar.lock, hence do not move
    # it to cleandirs (these are executed without holding the lock)
    rm -rf ${REPO_ISAR_DIR}/${DISTRO}/conf
    mkdir -p ${REPO_ISAR_DIR}/${DISTRO}/conf

    repo_create "${REPO_ISAR_DIR}"/"${DISTRO}" \
        "${REPO_ISAR_DB_DIR}"/"${DISTRO}" \
        "${DEBDISTRONAME}" \
        "${WORKDIR}/distributions.in" \
        "" \
        "${@ repo_expand_opt_fields(d, 'ISAR_APT_OPT_FIELD')}"
}

addtask cache_config after do_unpack before do_build
