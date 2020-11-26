# This software is a part of ISAR.
# Copyright (C) 2020 Siemens AG
#
# SPDX-License-Identifier: MIT

inherit repository

is_not_part_of_current_build() {
    local package="$( dpkg-deb --show --showformat '${Package}' "${1}" )"
    local output="$( grep -hs "^Package: ${package}" \
            "${IMAGE_ROOTFS}"/var/lib/dpkg/status \
            "${BUILDCHROOT_HOST_DIR}"/var/lib/dpkg/status \
            "${BUILDCHROOT_TARGET_DIR}"/var/lib/dpkg/status )"
    [ -z "${output}" ]
}

debsrc_download() {
    export rootfs="$1"
    export rootfs_distro="$2"
    mkdir -p "${DEBSRCDIR}"/"${rootfs_distro}"
    sudo -E -s <<'EOSUDO'
    mkdir -p "${rootfs}/deb-src"
    mountpoint -q "${rootfs}/deb-src" || \
    mount --bind "${DEBSRCDIR}" "${rootfs}/deb-src"
EOSUDO
    ( flock 9
    set -e
    printenv | grep -q BB_VERBOSE_LOGS && set -x
    find "${rootfs}/var/cache/apt/archives/" -maxdepth 1 -type f -iname '*\.deb' | while read package; do
        is_not_part_of_current_build "${package}" && continue
        local src="$( dpkg-deb --show --showformat '${source:Package}' "${package}" )"
        local version="$( dpkg-deb --show --showformat '${source:Version}' "${package}" )"
        local dscfile=$(find "${DEBSRCDIR}"/"${rootfs_distro}" -name "${src}_${version}.dsc")
        [ -n "$dscfile" ] && continue

        sudo -E chroot --userspec=$( id -u ):$( id -g ) ${rootfs} \
            sh -c ' mkdir -p "/deb-src/${1}/${2}" && cd "/deb-src/${1}/${2}" && apt-get -y --download-only --only-source source "$2"="$3" ' download-src "${rootfs_distro}" "${src}" "${version}"
    done
    ) 9>"${DEBSRCDIR}/${rootfs_distro}.lock"
    sudo -E -s <<'EOSUDO'
    mountpoint -q "${rootfs}/deb-src" && \
    umount -l "${rootfs}/deb-src"
    rm -rf "${rootfs}/deb-src"
EOSUDO
}

deb_dl_dir_import() {
    export pc="${DEBDIR}/${2}"
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
    export pc="${DEBDIR}/${2}"
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
