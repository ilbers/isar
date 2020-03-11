# This software is a part of ISAR.
# Copyright (C) 2017-2020 Siemens AG
# Copyright (C) 2019 ilbers GmbH
#
# SPDX-License-Identifier: MIT

repo_create() {
    local dir="$1"
    local dbdir="$2"
    local codename="$3"
    local distros_in="$4"
    local keyfiles="$5"

    if [ -n "${GNUPGHOME}" ]; then
        export GNUPGHOME="${GNUPGHOME}"
    fi

    if [ ! -f "${dir}"/conf/distributions ]; then
        mkdir -p "${dir}"/conf/
        sed -e "s#{CODENAME}#${codename}#g" ${distros_in} \
            >"${dir}"/conf/distributions
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

repo_add_srcpackage() {
    local dir="$1"
    local dbdir="$2"
    local codename="$3"
    shift; shift; shift

    if [ -n "${GNUPGHOME}" ]; then
        export GNUPGHOME="${GNUPGHOME}"
    fi
    reprepro -b "${dir}" --dbdir "${dbdir}" -C main -P source \
        includedsc "${codename}" \
        "$@"
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

repo_contains_package() {
    local dir="$1"
    local file="$2"
    local package

    package=$(find ${dir} -name ${file##*/})
    if [ -n "$package" ]; then
        # yes
        cmp --silent "$package" "$file" && return 0

        # yes but not the exact same file
        return 1
    fi
    # no
    return 2
}
