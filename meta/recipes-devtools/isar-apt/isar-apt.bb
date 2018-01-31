# This software is a part of ISAR.
# Copyright (C) 2015-2017 ilbers GmbH

SRC_URI = "file://distributions.in"

CACHE_CONF_DIR = "${DEPLOY_DIR_APT}/${DISTRO}/conf"
do_cache_config[dirs] = "${CACHE_CONF_DIR}"
do_cache_config[stamp-extra-info] = "${DISTRO}"
do_cache_config[lockfiles] = "${DEPLOY_DIR_APT}/isar.lock"

# Generate reprepro config for current distro if it doesn't exist. Once it's
# generated, this task should do nothing.
do_cache_config() {
    if [ ! -e "${CACHE_CONF_DIR}/distributions" ]; then
        sed -e "s#{DISTRO_NAME}#"${DEBDISTRONAME}"#g" \
            ${WORKDIR}/distributions.in > ${CACHE_CONF_DIR}/distributions
    fi

    path_cache="${DEPLOY_DIR_APT}/${DISTRO}"
    path_databases="${DEPLOY_DIR_DB}/${DISTRO}"

    if [ ! -d "${path_databases}" ]; then
        reprepro -b ${path_cache} \
                 --dbdir ${path_databases} \
                 export ${DEBDISTRONAME}
    fi
}

addtask cache_config after do_unpack before do_build
