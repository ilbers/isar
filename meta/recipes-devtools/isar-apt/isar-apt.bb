# This software is a part of ISAR.
# Copyright (C) 2015-2017 ilbers GmbH

SRC_URI = "file://distributions.in"

CACHE_CONF_DIR = "${REPO_ISAR_DIR}/${DISTRO}/conf"
do_cache_config[dirs] = "${CACHE_CONF_DIR}"
do_cache_config[stamp-extra-info] = "${DISTRO}"
do_cache_config[lockfiles] = "${REPO_ISAR_DIR}/isar.lock"

# Generate reprepro config for current distro if it doesn't exist. Once it's
# generated, this task should do nothing.
do_cache_config() {
    if [ ! -e "${CACHE_CONF_DIR}/distributions" ]; then
        sed -e "s#{DISTRO_NAME}#"${DEBDISTRONAME}"#g" \
            ${WORKDIR}/distributions.in > ${CACHE_CONF_DIR}/distributions
    fi

    path_cache="${REPO_ISAR_DIR}/${DISTRO}"
    path_databases="${REPO_ISAR_DB_DIR}/${DISTRO}"

    if [ ! -d "${path_databases}" ]; then
        if [ -n "${GNUPGHOME}" ]; then
            export GNUPGHOME="${GNUPGHOME}"
        fi
        reprepro -b ${path_cache} \
                 --dbdir ${path_databases} \
                 export ${DEBDISTRONAME}
    fi
}

addtask cache_config after do_unpack before do_build
