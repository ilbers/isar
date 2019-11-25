# This software is a part of ISAR.
# Copyright (C) Siemens AG, 2019
#
# SPDX-License-Identifier: MIT
#
# This class extends the image.bbclass to supply the creation of cache repositories

inherit repository

compare_pkg_md5sums() {
   pkg1=$1
   pkg2=$2

   md1=$(md5sum $pkg1 | cut -d ' ' -f 1)
   md2=$(md5sum $pkg2 | cut -d ' ' -f 1)

   [ "$md1" = "$md2" ]
}

populate_base_apt() {
    find "${DEBDIR}"/"${DISTRO}" -name '*\.deb' | while read package; do
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
