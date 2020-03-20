# This software is a part of ISAR.
# Copyright (C) Siemens AG, 2019
#
# SPDX-License-Identifier: MIT
#
# This class extends the image.bbclass to supply the creation of cache repositories

inherit repository

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

do_cache_base_repo[depends] = "base-apt:do_cache_config"
do_cache_base_repo[lockfiles] = "${REPO_BASE_DIR}/isar.lock"
do_cache_base_repo[stamp-extra-info] = "${DISTRO}-${MACHINE}"
do_cache_base_repo() {
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
addtask cache_base_repo after do_rootfs do_install_imager_deps
