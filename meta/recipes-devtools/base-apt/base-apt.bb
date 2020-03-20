# This software is a part of ISAR.
# Copyright (C) 2018 ilbers GmbH
# Copyright (C) 2020 Siemens AG
#
# SPDX-License-Identifier: MIT

inherit repository

BASE_REPO_KEY ?= ""
KEYFILES ?= ""

populate_base_apt() {
    find "${DEBDIR}"/"${DISTRO}" -name '*\.deb' | while read package; do
        # NOTE: due to packages stored by reprepro are not modified, we can
        # use search by filename to check if package is already in repo. In
        # addition, md5sums are compared to ensure that the package is the
        # same and should not be overwritten. This method is easier and more
        # robust than querying reprepro by name.

        # Check if this package is taken from Isar-apt, if so - ingore it.
        repo_contains_package "${REPO_ISAR_DIR}/${DISTRO}" "${package}" && \
            continue

        # Check if this package is already in base-apt
        ret=0
        repo_contains_package "${REPO_BASE_DIR}/${BASE_DISTRO}" "${package}" ||
            ret=$?
        [ "${ret}" = "0" ] && continue
        if [ "${ret}" = "1" ]; then
            repo_del_package "${REPO_BASE_DIR}"/"${BASE_DISTRO}" \
                "${REPO_BASE_DB_DIR}"/"${BASE_DISTRO}" \
                "${BASE_DISTRO_CODENAME}" \
                "${base_apt_p}"
        fi

        repo_add_packages "${REPO_BASE_DIR}"/"${BASE_DISTRO}" \
            "${REPO_BASE_DB_DIR}"/"${BASE_DISTRO}" \
            "${BASE_DISTRO_CODENAME}" \
            "${package}"
    done

    find "${DEBSRCDIR}"/"${DISTRO}" -name '*\.dsc' | while read package; do
        repo_add_srcpackage "${REPO_BASE_DIR}"/"${BASE_DISTRO}" \
            "${REPO_BASE_DB_DIR}"/"${BASE_DISTRO}" \
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
        "${KEYFILES}"

    if [ -d '${BUILDCHROOT_HOST_DIR}/var/cache/apt' ] &&
        [ '${DISTRO}' != '${HOST_DISTRO}' ]; then
        # We would need two separate repository paths for that.
        # Otherwise packages (especially the 'all' arch ones) from one
        # distribution can influence the package versions of the other
        # distribution.
        bbfatal "Different host and target distributions are currently not supported." \
                "Try it without cross-build."
    fi

    populate_base_apt
}

python do_cache() {
    if not bb.utils.to_boolean(d.getVar('ISAR_USE_CACHED_BASE_REPO')):
        return 0

    for key in d.getVar('BASE_REPO_KEY').split():
        d.appendVar("SRC_URI", " %s" % key)
        fetcher = bb.fetch2.Fetch([key], d)
        filename = fetcher.localpath(key)
        d.appendVar("KEYFILES", " %s" % filename)

    bb.build.exec_func('repo', d)
}

addtask cache after do_unpack before do_build
