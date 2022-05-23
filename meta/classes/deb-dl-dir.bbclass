# This software is a part of ISAR.
# Copyright (C) 2020 Siemens AG
#
# SPDX-License-Identifier: MIT

inherit repository

is_not_part_of_current_build() {
    local package="$( dpkg-deb --show --showformat '${Package}' "${1}" )"
    local arch="$( dpkg-deb --show --showformat '${Architecture}' "${1}" )"
    local version="$( dpkg-deb --show --showformat '${Version}' "${1}" )"
    # Since we are parsing all the debs in DEBDIR, we can to some extend
    # try to eliminate some debs that are not part of the current multiconfig
    # build using the below method.
    local output="$( grep -xhs ".* status installed ${package}:${arch} ${version}" \
            "${IMAGE_ROOTFS}"/var/log/dpkg.log \
            "${SCHROOT_HOST_DIR}"/var/log/dpkg.log \
            "${SCHROOT_TARGET_DIR}"/var/log/dpkg.log \
            "${SCHROOT_HOST_DIR}"/tmp/dpkg_common.log \
            "${SCHROOT_TARGET_DIR}"/tmp/dpkg_common.log \
            "${BUILDCHROOT_HOST_DIR}"/var/log/dpkg.log \
            "${BUILDCHROOT_TARGET_DIR}"/var/log/dpkg.log | head -1 )"

    [ -z "${output}" ]
}

debsrc_do_mounts() {
    sudo -s <<EOSUDO
    set -e
    mkdir -p "${1}/deb-src"
    mountpoint -q "${1}/deb-src" || \
    mount --bind "${DEBSRCDIR}" "${1}/deb-src"
EOSUDO
}

debsrc_undo_mounts() {
    sudo -s <<EOSUDO
    set -e
    mkdir -p "${1}/deb-src"
    mountpoint -q "${1}/deb-src" && \
    umount -l "${1}/deb-src"
    rm -rf "${1}/deb-src"
EOSUDO
}

debsrc_download() {
    export rootfs="$1"
    export rootfs_distro="$2"
    mkdir -p "${DEBSRCDIR}"/"${rootfs_distro}"

    debsrc_do_mounts "${rootfs}"

    ( flock 9
    set -e
    printenv | grep -q BB_VERBOSE_LOGS && set -x
    find "${rootfs}/var/cache/apt/archives/" -maxdepth 1 -type f -iname '*\.deb' | while read package; do
        is_not_part_of_current_build "${package}" && continue
        # Get source package name if available, fallback to package name
        local src="$( dpkg-deb --field "${package}" Source | awk '{printf $1}' )"
        [ -z "$src" ] && src="$( dpkg-deb --field "${package}" Package )"
        # Get source package version if available, fallback to package version
        local version="$( dpkg-deb --field "${package}" Source |  awk '{gsub(/[()]/,""); printf $2}')"
        [ -z "$version" ] && version="$( dpkg-deb --field "${package}" Version )"
        # TODO: get back to the code below when debian bug #1004372 is fixed
        # local src="$( dpkg-deb --show --showformat '${source:Package}' "${package}" )"
        # local version="$( dpkg-deb --show --showformat '${source:Version}' "${package}" )"
        local dscfile=$(find "${DEBSRCDIR}"/"${rootfs_distro}" -name "${src}_${version}.dsc")
        [ -n "$dscfile" ] && continue

        sudo -E chroot --userspec=$( id -u ):$( id -g ) ${rootfs} \
            sh -c ' mkdir -p "/deb-src/${1}/${2}" && cd "/deb-src/${1}/${2}" && apt-get -y --download-only --only-source source "$2"="$3" ' download-src "${rootfs_distro}" "${src}" "${version}"
    done
    ) 9>"${DEBSRCDIR}/${rootfs_distro}.lock"

    debsrc_undo_mounts "${rootfs}"
}

deb_dl_dir_import() {
    export pc="${DEBDIR}/${2}"
    export rootfs="${1}"
    sudo mkdir -p "${rootfs}"/var/cache/apt/archives/
    [ ! -d "${pc}" ] && return 0
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
