# This software is a part of ISAR.
# Copyright (C) 2020 Siemens AG
#
# SPDX-License-Identifier: MIT

inherit repository

deb_dl_dir_import() {
    export pc="${DEBDIR}/${DISTRO}/"
    export rootfs="${1}"
    [ ! -d "${pc}" ] && return 0
    sudo mkdir -p "${rootfs}"/var/cache/apt/archives/
    flock -s "${pc}".lock -c '
        set -e
        printenv | grep -q BB_VERBOSE_LOGS && set -x

        sudo find "${pc}" -type f -iname "*\.deb" -exec \
            cp -n --no-preserve=owner -t "${rootfs}"/var/cache/apt/archives/ {} +
    '
}

deb_dl_dir_export() {
    export pc="${DEBDIR}/${DISTRO}/"
    export rootfs="${1}"
    mkdir -p "${pc}"
    flock "${pc}".lock -c '
        set -e
        printenv | grep -q BB_VERBOSE_LOGS && set -x

        find "${rootfs}"/var/cache/apt/archives/ \
            -maxdepth 1 -type f -iname '*\.deb' |\
        while read p; do
            # skip files from a previous export
            [ -f "${pc}/${p##*/}" ] && continue
            # can not reuse bitbake function here, this is basically
            # "repo_contains_package"
            package=$(find "${REPO_ISAR_DIR}"/"${DISTRO}" -name ${p##*/})
            if [ -n "$package" ]; then
                cmp --silent "$package" "$p" && continue
            fi
            sudo cp -n "${p}" "${pc}"
        done
        sudo chown -R $(id -u):$(id -g) "${pc}"
    '
}
