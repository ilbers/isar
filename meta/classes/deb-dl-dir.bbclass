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

    # Use apt-ftparchive to scan all .deb files found in the download directory
    # and produce an index that we can "parse" with awk. This is much faster
    # than parsing each .deb file individually using dpkg-deb. Lines from the
    # index we need are:
    #
    #    Package: <binary-name>
    #    Version: <binary-version>
    #    Source: <source-name> (<source-version>)
    #
    # If Source is omitted, then <source-name>=<binary-name> and
    # if <source-version> is not specified then it is <binary-version>.
    # The awk script handles these optional fields. It looks for Size: as a
    # trigger to print the source,version tupple

    apt-ftparchive --md5=no --sha1=no --sha256=no --sha512=no \
                   -a "${DISTRO_ARCH}" packages \
                   "${rootfs}/var/cache/apt/archives" \
    | awk '/^Package:/ { s=$2; }
           /^Version:/ { v=$2; next }
           /^Source:/ { s=$2; if ($3 ~ /^\(/) v=substr($3, 2, length($3)-2) }
           /^Size:/ { print s, v}' \
    | sort -u \
    | while read src version; do
        # Name of the .dsc file does not include Epoch, remove it before checking
        # if sources were already downloaded. Avoid using sed here to reduce the
        # number of processes being spawned by this function: we assume that the
        # version is correctly formatted and simply strip everything up to the
        # first colon
        dscname="${src}_${version#*:}.dsc"
        [ -f "${DEBSRCDIR}"/"${rootfs_distro}"/"${src}"/"${dscname}" ] || {
            # use apt-get source to download sources in DEBSRCDIR
            sudo -E chroot --userspec=$( id -u ):$( id -g ) ${rootfs} \
                sh -c ' mkdir -p "/deb-src/${1}/${2}" && cd "/deb-src/${1}/${2}" && apt-get -y --download-only --only-source source "$2"="$3" ' download-src "${rootfs_distro}" "${src}" "${version}"
        }
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
