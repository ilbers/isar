# This software is a part of ISAR.
# Copyright (C) 2017-2020 Siemens AG
# Copyright (C) 2019 ilbers GmbH
#
# SPDX-License-Identifier: MIT

repo_create() {
    local dir="$1"
    local dbdir="$2"
    local codename="$3"
    local keyfiles="$4"

    if [ -n "${GNUPGHOME}" ]; then
        export GNUPGHOME="${GNUPGHOME}"
    fi

    if [ ! -f "${dir}"/conf/distributions ]; then
        mkdir -p "${dir}"/conf/
        cat <<EOF > "${dir}"/conf/distributions
Codename: ${codename}
Architectures: i386 armhf arm64 amd64 mipsel riscv64 source
Components: main
EOF
        if [ -n "${keyfiles}" ] ; then
	    local option=""
	    for key in ${keyfiles}; do
	      keyid=$(gpg --keyid-format 0xlong --with-colons ${key} 2>/dev/null | grep "^pub:" | awk -F':' '{print $5;}')
	      option="${option}${keyid} "
	    done
	    echo "SignWith: ${option}" >> "${dir}"/conf/distributions
        fi
    fi
    if [ ! -d "${dbdir}" ]; then
        reprepro -b "${dir}" --dbdir "${dbdir}" export "${codename}"
    fi
}

repo_add_packages() {
    local dir="$1"
    local dbdir="$2"
    local codename="$3"
    shift; shift; shift

    if [ -n "${GNUPGHOME}" ]; then
        export GNUPGHOME="${GNUPGHOME}"
    fi
    reprepro -b "${dir}" --dbdir "${dbdir}" -C main \
        includedeb "${codename}" \
        "$@"
}

repo_del_package() {
    local dir="$1"
    local dbdir="$2"
    local codename="$3"
    local file="$4"

    if [ -n "${GNUPGHOME}" ]; then
        export GNUPGHOME="${GNUPGHOME}"
    fi
    local p=$( dpkg-deb --show --showformat '${Package}' "${file}" )
    local a=$( dpkg-deb --show --showformat '${Architecture}' "${file}" )
    # removing "all" means no arch
    local aarg="-A ${a}"
    [ "${a}" = "all" ] && aarg=""
    reprepro -b "${dir}" --dbdir "${dbdir}" -C main ${aarg} \
        remove "${codename}" \
        "${p}"
}
