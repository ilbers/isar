# This software is a part of ISAR.
# Copyright (C) 2023 ilbers GmbH
#
# SPDX-License-Identifier: MIT

inherit dpkg-base

DPKG_SOURCE_EXTRA_ARGS ?= "-I"

DEBIAN_SOURCE ?= "${BPN}"

do_dpkg_source() {
    # Create a .dsc file from source directory to use it with sbuild
    DEB_SOURCE_NAME=$(dpkg-parsechangelog --show-field Source --file ${WORKDIR}/${PPS}/debian/changelog)
    if [ "${DEB_SOURCE_NAME}" != "${DEBIAN_SOURCE}" ]; then
        bbfatal "DEBIAN_SOURCE (${DEBIAN_SOURCE}) not aligned with source name used in control files (${DEB_SOURCE_NAME})"
    fi
    find ${WORKDIR} -maxdepth 1 -name "${DEBIAN_SOURCE}_*.dsc" -delete
    sh -c "cd ${WORKDIR}; dpkg-source ${DPKG_SOURCE_EXTRA_ARGS} -b ${PPS}"
}
addtask dpkg_source after do_prepare_build before do_dpkg_build

do_deploy_source[depends] += "isar-apt:do_cache_config"
do_deploy_source[lockfiles] = "${REPO_ISAR_DIR}/isar.lock"
do_deploy_source[dirs] = "${S}"
do_deploy_source() {
    repo_del_srcpackage "${REPO_ISAR_DIR}"/"${DISTRO}" \
        "${REPO_ISAR_DB_DIR}"/"${DISTRO}" "${DEBDISTRONAME}" "${DEBIAN_SOURCE}"
    DSC_FILE=$(find ${WORKDIR} -maxdepth 1 -name "${DEBIAN_SOURCE}_*.dsc")
    if [ -n "${DSC_FILE}" ]; then
        repo_add_srcpackage "${REPO_ISAR_DIR}"/"${DISTRO}" \
            "${REPO_ISAR_DB_DIR}"/"${DISTRO}" \
            "${DEBDISTRONAME}" \
            "${DSC_FILE}"
    fi
}
addtask deploy_source after do_dpkg_source before do_dpkg_build
