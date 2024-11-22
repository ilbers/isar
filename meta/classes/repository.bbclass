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
    reprepro -b "${dir}" --dbdir "${dbdir}" -C main -S - -P source \
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

repo_del_srcpackage() {
    local dir="$1"
    local dbdir="$2"
    local codename="$3"
    local packagename="$4"

    if [ -n "${GNUPGHOME}" ]; then
        export GNUPGHOME="${GNUPGHOME}"
    fi
    reprepro -b "${dir}" --dbdir "${dbdir}" -A source \
        remove "${codename}" \
        "${packagename}"
}

repo_del_package() {
    local dir="$1"
    local dbdir="$2"
    local codename="$3"
    local file="$4"

    if [ -n "${GNUPGHOME}" ]; then
        export GNUPGHOME="${GNUPGHOME}"
    fi
    set -- $( dpkg-deb --show --showformat '${Package} ${Architecture}' "${file}" )
    local p="${1}" a="${2}"
    reprepro -b "${dir}" --dbdir "${dbdir}" -C main \
        removefilter "${codename}" \
        'Package (= '${p}'), Architecture (= '${a}'), $PackageType (= deb)'
}

repo_contains_package() {
    local dir="$1"
    local dbdir="$2"
    local codename="$3"
    local file="$4"
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

repo_sanity_test() {
    local dir="$1"
    local dbdir="$2"
    if [ "${@bb.utils.contains('BASE_REPO_FEATURES', 'cache-deb-src', 'yes', 'no', d)}" = "yes" ];then
        local output="$( reprepro -s -b "${dir}" --dbdir "${dbdir}" sourcemissing )"
        if [ -n "${output}" ]; then
            bbfatal "One or more sources are missing in repo. ${output}"
        fi
    fi
}
