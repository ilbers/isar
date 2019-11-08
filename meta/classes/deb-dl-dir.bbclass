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
    flock -s "${pc}".lock -c ' \
        sudo find "${pc}" -type f -iname '*\.deb' -exec \
            cp -f --no-preserve=owner -t "${rootfs}"/var/cache/apt/archives/ '{}' +
    '
}

deb_dl_dir_export() {
    export pc="${DEBDIR}/${DISTRO}/"
    export rootfs="${1}"
    mkdir -p "${pc}"
    flock "${pc}".lock -c ' \
        find "${rootfs}"/var/cache/apt/archives/ -type f -iname '*\.deb' |\
        while read p; do
            repo_contains_package "${REPO_ISAR_DIR}"/"${DISTRO}" "${p}" && \
                continue
            sudo cp -f "${p}" "${pc}"
        done
        sudo chown -R $(id -u):$(id -g) "${pc}"
    '
}
