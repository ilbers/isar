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
addtask dpkg_source after do_prepare_build

CLEANFUNCS += "deb_clean_source"

deb_clean_source() {
    repo_del_srcpackage "${REPO_ISAR_DIR}"/"${DISTRO}" \
        "${REPO_ISAR_DB_DIR}"/"${DISTRO}" "${DEBDISTRONAME}" "${DEBIAN_SOURCE}"
}

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
addtask deploy_source after do_dpkg_source

do_dpkg_build[depends] += "${BPN}:do_deploy_source"

SCHROOT_MOUNTS = "${WORKDIR}:/work ${REPO_ISAR_DIR}/${DISTRO}:/isar-apt"

do_fetch_common_source[depends] += "${SCHROOT_DEP} ${BPN}:do_deploy_source"
do_fetch_common_source[lockfiles] = "${REPO_ISAR_DIR}/isar.lock"
do_fetch_common_source[network] = "${TASK_USE_SUDO}"
do_fetch_common_source() {
    schroot_create_configs
    insert_mounts

    session_id=$(schroot -q -b -c ${SBUILD_CHROOT})
    echo "Started session: ${session_id}"

    schroot_cleanup() {
        schroot -q -f -e -c ${session_id} > /dev/null 2>&1
        remove_mounts > /dev/null 2>&1
        schroot_delete_configs
    }
    trap 'exit 1' INT HUP QUIT TERM ALRM USR1
    trap 'schroot_cleanup' EXIT

    schroot -r -c ${session_id} -d / -u root -- \
        apt-get update -o Dir::Etc::SourceList="sources.list.d/isar-apt.list" -o Dir::Etc::SourceParts="-" -o APT::Get::List-Cleanup="0"
    schroot -r -c ${session_id} -d / -- \
        sh -c '
            cd /work
            apt-get -y --download-only --only-source -o Acquire::Source-Symlinks="false" source ${DEBIAN_SOURCE}'

    schroot -e -c ${session_id}
    remove_mounts
    schroot_delete_configs
}
addtask fetch_common_source

do_dpkg_build[depends] += "${@'${PN}:do_dpkg_source' if '${PN}' == '${BPN}' else '${PN}:do_fetch_common_source'}"
do_clean[depends] += "${@'' if '${PN}' == '${BPN}' else '${BPN}:do_clean'}"
