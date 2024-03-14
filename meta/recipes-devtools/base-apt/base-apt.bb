# This software is a part of ISAR.
# Copyright (C) 2018 ilbers GmbH
# Copyright (C) 2020 Siemens AG
#
# SPDX-License-Identifier: MIT

inherit repository

SRC_URI = "file://distributions.in"

BASE_REPO_KEY ?= ""
KEYFILES ?= ""
BASE_REPO_FEATURES ?= ""

populate_base_apt() {
    base_distro="${1}"

    find "${DEBDIR}"/"${base_distro}-${BASE_DISTRO_CODENAME}" -name '*\.deb' | while read package; do
        # NOTE: due to packages stored by reprepro are not modified, we can
        # use search by filename to check if package is already in repo. In
        # addition, md5sums are compared to ensure that the package is the
        # same and should not be overwritten. This method is easier and more
        # robust than querying reprepro by name.

        # Check if this package is already in base-apt
        ret=0
        repo_contains_package "${REPO_BASE_DIR}/${base_distro}" "${package}" ||
            ret=$?
        [ "${ret}" = "0" ] && continue
        if [ "${ret}" = "1" ]; then
            repo_del_package "${REPO_BASE_DIR}"/"${base_distro}" \
                "${REPO_BASE_DB_DIR}"/"${base_distro}" \
                "${BASE_DISTRO_CODENAME}" \
                "${package}"
        fi

        repo_add_packages "${REPO_BASE_DIR}"/"${base_distro}" \
            "${REPO_BASE_DB_DIR}"/"${base_distro}" \
            "${BASE_DISTRO_CODENAME}" \
            "${package}"
    done

    find "${DEBSRCDIR}"/"${base_distro}-${BASE_DISTRO_CODENAME}" -name '*\.dsc' | while read package; do
        repo_add_srcpackage "${REPO_BASE_DIR}"/"${base_distro}" \
            "${REPO_BASE_DB_DIR}"/"${base_distro}" \
            "${BASE_DISTRO_CODENAME}" \
            "${package}"
    done
}

do_cache[stamp-extra-info] = "${DISTRO}"
do_cache[lockfiles] = "${REPO_BASE_DIR}/isar.lock"

repo() {
    repo_create "${REPO_BASE_DIR}"/"${BASE_DISTRO}" \
        "${REPO_BASE_DB_DIR}"/"${BASE_DISTRO}" \
        "${BASE_DISTRO_CODENAME}" \
        "${WORKDIR}/distributions.in" \
        "${KEYFILES}"
    if [ "${ISAR_USE_CACHED_BASE_REPO}" = "1" ] && \
       [ "${ISAR_PREFETCH_BASE_APT}" != "1" ]; then
        populate_base_apt "${BASE_DISTRO}"
        repo_sanity_test "${REPO_BASE_DIR}"/"${BASE_DISTRO}" \
            "${REPO_BASE_DB_DIR}"/"${BASE_DISTRO}"
    fi

    if [ '${BASE_DISTRO}' != '${HOST_BASE_DISTRO}' ]; then
        repo_create "${REPO_BASE_DIR}"/"${HOST_BASE_DISTRO}" \
            "${REPO_BASE_DB_DIR}"/"${HOST_BASE_DISTRO}" \
            "${BASE_DISTRO_CODENAME}" \
            "${WORKDIR}/distributions.in" \
            "${KEYFILES}"
        if [ "${ISAR_USE_CACHED_BASE_REPO}" = "1" ] && \
           [ "${ISAR_PREFETCH_BASE_APT}" != "1" ]; then
            populate_base_apt "${HOST_BASE_DISTRO}"
            repo_sanity_test "${REPO_BASE_DIR}"/"${HOST_BASE_DISTRO}" \
                "${REPO_BASE_DB_DIR}"/"${HOST_BASE_DISTRO}"
        fi
    fi
}

python do_cache() {
    if not bb.utils.to_boolean(d.getVar('ISAR_PREFETCH_BASE_APT')) and \
       not bb.utils.to_boolean(d.getVar('ISAR_USE_CACHED_BASE_REPO')):
        return 0

    for key in d.getVar('BASE_REPO_KEY').split():
        d.appendVar("SRC_URI", " %s" % key)
        fetcher = bb.fetch2.Fetch([key], d)
        filename = fetcher.localpath(key)
        d.appendVar("KEYFILES", " %s" % filename)

    bb.build.exec_func('repo', d)
}

addtask cache after do_unpack before do_build
