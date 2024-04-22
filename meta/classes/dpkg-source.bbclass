# This software is a part of ISAR.
# Copyright (C) 2023 ilbers GmbH
#
# SPDX-License-Identifier: MIT

inherit dpkg-base

DPKG_SOURCE_EXTRA_ARGS ?= "-I"

do_dpkg_source() {
    # Create a .dsc file from source directory to use it with sbuild
    DEB_SOURCE_NAME=$(dpkg-parsechangelog --show-field Source --file ${WORKDIR}/${PPS}/debian/changelog)
    find ${WORKDIR} -name "${DEB_SOURCE_NAME}*.dsc" -maxdepth 1 -delete
    sh -c "cd ${WORKDIR}; dpkg-source ${DPKG_SOURCE_EXTRA_ARGS} -b ${PPS}"
}
addtask dpkg_source after do_prepare_build before do_dpkg_build

do_deploy_source[depends] += "isar-apt:do_cache_config"
do_deploy_source[lockfiles] = "${REPO_ISAR_DIR}/isar.lock"
do_deploy_source[dirs] = "${S}"
do_deploy_source() {
    repo_del_srcpackage "${REPO_ISAR_DIR}"/"${DISTRO}" \
        "${REPO_ISAR_DB_DIR}"/"${DISTRO}" "${DEBDISTRONAME}" "${BPN}"
    find "${S}/../" -name '*\.dsc' -maxdepth 1 | while read package; do
        repo_add_srcpackage "${REPO_ISAR_DIR}"/"${DISTRO}" \
            "${REPO_ISAR_DB_DIR}"/"${DISTRO}" \
            "${DEBDISTRONAME}" \
            "${package}"
    done
}
addtask deploy_source after do_dpkg_source before do_dpkg_build
