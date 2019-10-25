# This software is a part of ISAR.
# Copyright (C) 2018 ilbers GmbH
# Copyright (C) 2020 Siemens AG
#
# SPDX-License-Identifier: MIT

inherit repository

compare_pkg_md5sums() {
   pkg1=$1
   pkg2=$2

   md1=$(md5sum $pkg1 | cut -d ' ' -f 1)
   md2=$(md5sum $pkg2 | cut -d ' ' -f 1)

   [ "$md1" = "$md2" ]
}

populate_base_apt() {
    search_dir=$1

    find $search_dir -name '*.deb' | while read package; do
        # NOTE: due to packages stored by reprepro are not modified, we can
        # use search by filename to check if package is already in repo. In
        # addition, md5sums are compared to ensure that the package is the
        # same and should not be overwritten. This method is easier and more
        # robust than querying reprepro by name.

        # Check if this package is taken from Isar-apt, if so - ignore it.
        base_name=${package##*/}
        isar_apt_p=$(find ${REPO_ISAR_DIR}/${DISTRO} -name $base_name)
        if [ -n "$isar_apt_p" ]; then
            # Check if MD5 sums are identical. This helps to avoid the case
            # when packages is overridden from another repo.
            compare_pkg_md5sums "$package" "$isar_apt_p" && continue
        fi

        # Check if this package is already in base-apt
        base_apt_p=$(find ${REPO_BASE_DIR}/${BASE_DISTRO} -name $base_name)
        if [ -n "$base_apt_p" ]; then
            compare_pkg_md5sums "$package" "$base_apt_p" && continue

            # md5sum differs, so remove the package from base-apt
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

    find $search_dir -name '*.dsc' | while read package; do
        repo_add_srcpackage "${REPO_BASE_DIR}"/"${BASE_DISTRO}" \
            "${REPO_BASE_DB_DIR}"/"${BASE_DISTRO}" \
            "${BASE_DISTRO_CODENAME}" \
            "${package}"
    done
}
