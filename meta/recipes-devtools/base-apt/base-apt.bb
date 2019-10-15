# This software is a part of ISAR.
# Copyright (C) 2018 ilbers GmbH

SRC_URI = "file://distributions.in"

BASE_REPO_KEY ?= ""
KEYFILES ?= ""

CACHE_CONF_DIR = "${REPO_BASE_DIR}/${BASE_DISTRO}/conf"
do_cache_config[dirs] = "${CACHE_CONF_DIR}"
do_cache_config[stamp-extra-info] = "${DISTRO}"
do_cache_config[lockfiles] = "${REPO_BASE_DIR}/isar.lock"

# Generate reprepro config for current distro if it doesn't exist. Once it's
# generated, this task should do nothing.
repo_config() {
    if [ ! -e "${CACHE_CONF_DIR}/distributions" ]; then
        sed -e "s#{CODENAME}#"${BASE_DISTRO_CODENAME}"#g" \
            ${WORKDIR}/distributions.in > ${CACHE_CONF_DIR}/distributions
        if [ -n "${KEYFILES}" ]; then
            option=""
            for key in ${KEYFILES}; do
                keyid=$(gpg --keyid-format 0xlong --with-colons ${key} 2>/dev/null | grep "^pub:" | awk -F':' '{print $5;}')
                option="${option}${keyid} "
            done
            # To generate Release.gpg
            echo "SignWith: ${option}" >> ${CACHE_CONF_DIR}/distributions
        fi
    fi

    path_cache="${REPO_BASE_DIR}/${BASE_DISTRO}"
    path_databases="${REPO_BASE_DB_DIR}/${BASE_DISTRO}"

    if [ ! -d "${path_databases}" ]; then
        if [ -n "${GNUPGHOME}" ]; then
            export GNUPGHOME="${GNUPGHOME}"
        fi
        reprepro -b ${path_cache} \
                 --dbdir ${path_databases} \
                 export ${BASE_DISTRO_CODENAME}
    fi
}

python do_cache_config() {
    for key in d.getVar('BASE_REPO_KEY').split():
        d.appendVar("SRC_URI", " %s" % key)
        fetcher = bb.fetch2.Fetch([key], d)
        filename = fetcher.localpath(key)
        d.appendVar("KEYFILES", " %s" % filename)

    bb.build.exec_func('repo_config', d)
}

addtask cache_config after do_unpack before do_build
