# This software is a part of ISAR.
# Copyright (C) 2020 Siemens AG
#
# SPDX-License-Identifier: MIT

inherit repository

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

    trap 'exit 1' INT HUP QUIT TERM ALRM USR1
    trap 'debsrc_undo_mounts "${rootfs}"' EXIT

    ( flock 9
    set -e
    printenv | grep -q BB_VERBOSE_LOGS && set -x
    sudo -E chroot --userspec=$( id -u ):$( id -g ) ${rootfs} \
        dpkg-query -f '${source:Package} ${source:Version}\n' -W | while read -r src srcver; do
            ver_stripped=$(echo "$srcver" | sed 's/^[0-9]*://')
            test -f "${DEBSRCDIR}/${rootfs_distro}/${src}/${src}_${ver_stripped}.dsc" && continue

            # Note: package built by using dpkg-prebuilt are tend to be missing
            sudo -E chroot --userspec=$( id -u ):$( id -g ) ${rootfs} \
                sh -c ' mkdir -p "/deb-src/${1}/${2}" && cd "/deb-src/${1}/${2}" && apt-get -y --download-only --only-source source "$2"="$3" ' \
                    download-src "${rootfs_distro}" "${src}" "${srcver}" || \
                    bbwarn "Failed to download source package ${src}_${srcver}"
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

    isar_debs="$(${SCRIPTSDIR}/lockrun.py -r -f '${REPO_ISAR_DIR}/isar.lock' -c \
    "find '${REPO_ISAR_DIR}/${DISTRO}' -name '*.deb' -print")"

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
