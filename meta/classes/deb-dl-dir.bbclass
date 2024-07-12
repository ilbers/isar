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
            "${SCHROOT_TARGET_DIR}"/tmp/dpkg_common.log | head -1 )"

    [ -z "${output}" ]
}

debsrc_do_mounts() {
    sudo -s <<EOSUDO
    set -e
    mkdir -p "${1}/deb-src"
    mountpoint -q "${1}/deb-src" || \
    mount -o bind,private "${DEBSRCDIR}" "${1}/deb-src"
EOSUDO
}

debsrc_undo_mounts() {
    sudo -s <<EOSUDO
    set -e
    mkdir -p "${1}/deb-src"
    mountpoint -q "${1}/deb-src" && \
    umount "${1}/deb-src"
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
        local src="$( dpkg-deb --show --showformat '${source:Package}' "${package}" )"
        local version="$( dpkg-deb --show --showformat '${source:Version}' "${package}" )"
        local dscname="$(echo ${src}_${version} | sed -e 's/_[0-9]\+:/_/')"
        local dscfile=$(find "${DEBSRCDIR}"/"${rootfs_distro}" -name "${dscname}.dsc")
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
    flock -s "${pc}".lock sudo -Es << 'EOSUDO'
        set -e
        printenv | grep -q BB_VERBOSE_LOGS && set -x

        find "${pc}" -type f -iname "*\.deb" |\
        while read p; do
            ln -Pf -t "${rootfs}"/var/cache/apt/archives/ "$p" 2>/dev/null ||
                cp -n --no-preserve=owner -t "${rootfs}"/var/cache/apt/archives/ "$p"
        done
EOSUDO
}

deb_dl_dir_export() {
    export pc="${DEBDIR}/${2}"
    export rootfs="${1}"
    export owner=$(id -u):$(id -g)
    mkdir -p "${pc}"

    isar_debs="\$(find '${REPO_ISAR_DIR}/${DISTRO}' -name '*.deb' -print)"

    flock "${pc}".lock sudo -Es << 'EOSUDO'
        set -e
        printenv | grep -q BB_VERBOSE_LOGS && set -x

        find "${rootfs}"/var/cache/apt/archives/ \
            -maxdepth 1 -type f -iname '*\.deb' |\
        while read p; do
            # skip files from a previous export
            [ -f "${pc}/${p##*/}" ] && continue
            # skip packages from isar-apt
            package=$(echo "$isar_debs" | grep -F -m 1 "${p##*/}" | cat)
            if [ -n "$package" ]; then
                cmp --silent "$package" "$p" && continue
            fi
            ln -Pf "${p}" "${pc}" 2>/dev/null ||
                cp -n "${p}" "${pc}"
        done
        chown -R ${owner} "${pc}"
EOSUDO
}
