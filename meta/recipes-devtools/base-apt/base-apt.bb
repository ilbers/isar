# This software is a part of ISAR.
# Copyright (C) 2018 ilbers GmbH

SRC_URI = "file://distributions.in"

inherit base-apt-helper

CACHE_CONF_DIR = "${REPO_BASE_DIR}/${BASE_DISTRO}/conf"
do_cache_config[dirs] = "${CACHE_CONF_DIR}"
do_cache_config[stamp-extra-info] = "${DISTRO}"
do_cache_config[lockfiles] = "${REPO_BASE_DIR}/isar.lock"

# Generate reprepro config for current distro if it doesn't exist. Once it's
# generated, this task should do nothing.
do_cache_config() {
    if [ ! -e "${CACHE_CONF_DIR}/distributions" ]; then
        sed -e "s#{CODENAME}#"${BASE_DISTRO_CODENAME}"#g" \
            ${WORKDIR}/distributions.in > ${CACHE_CONF_DIR}/distributions
    fi

    path_cache="${REPO_BASE_DIR}/${BASE_DISTRO}"
    path_databases="${REPO_BASE_DB_DIR}/${BASE_DISTRO}"

    if [ ! -d "${path_databases}" ]; then
        reprepro -b ${path_cache} \
                 --dbdir ${path_databases} \
                 export ${BASE_DISTRO_CODENAME}
    fi
}

addtask cache_config after do_build
