# This software is a part of Isar.
# Copyright (C) 2023 ilbers GmbH
#
# SPDX-License-Identifier: MIT

inherit dpkg-base

TAR_REPRO_OPTS ?= "--exclude=.git --exclude=debian \
--mtime=@${SOURCE_DATE_EPOCH} --clamp-mtime \
--owner=0 --group=0 --numeric-owner \
--sort=name"

DPKG_SOURCE_EXTRA_ARGS ?= "-I"

DEBIAN_SOURCE ?= "${BPN}"
SRCPKG_DIR = "${WORKDIR}/deploy-srcpkg"
DEPLOY_DIR_SRC = "${DEPLOY_DIR}/isar-source/${DISTRO}/${BPN}"
# DEPLOY_DIR_SRC is not qualified by DISTRO_ARCH or MACHINE, so all multiconfigs
# sharing DISTRO run do_dpkg_source and do_deploy_source of the same recipe on
# it, concurrently. Serialize the sstate clean/install of do_dpkg_source against
# do_deploy_source, so that the latter never sees a partially populated
# directory. Keep the lock next to, not inside, DEPLOY_DIR_SRC so that
# sstate_clean_manifest() cannot sweep it away.
DEPLOY_DIR_SRC_LOCK = "${DEPLOY_DIR}/isar-source/${DISTRO}/${BPN}.lock"

do_dpkg_source[cleandirs] = "${SRCPKG_DIR}"
do_dpkg_source[sstate-inputdirs] = "${SRCPKG_DIR}"
do_dpkg_source[sstate-outputdirs] = "${DEPLOY_DIR_SRC}"
do_dpkg_source[sstate-lockfile] = "${DEPLOY_DIR_SRC_LOCK}"
do_dpkg_source() {
    # Create a .dsc file from source directory to use it with sbuild
    DEB_SOURCE_NAME=$(dpkg-parsechangelog --show-field Source --file ${WORKDIR}/${PPS}/debian/changelog)
    if [ "${DEB_SOURCE_NAME}" != "${DEBIAN_SOURCE}" ]; then
        bbfatal "DEBIAN_SOURCE (${DEBIAN_SOURCE}) not aligned with source name used in control files (${DEB_SOURCE_NAME})"
    fi
    find ${WORKDIR} -maxdepth 1 -name "${DEBIAN_SOURCE}_*.dsc" -delete
    sh -c "cd ${WORKDIR}; dpkg-source ${DPKG_SOURCE_EXTRA_ARGS} -b ${PPS}"
    # move packages to deploy directory
    find ${WORKDIR} -maxdepth 1 \( -name "${DEBIAN_SOURCE}_*.tar.*" -o -name "${DEBIAN_SOURCE}_*.dsc" \) -exec mv {} ${SRCPKG_DIR}/ \;
}
addtask dpkg_source after do_prepare_build

SSTATETASKS += "do_dpkg_source"

python do_dpkg_source_setscene() {
    sstate_setscene(d)
}

addtask dpkg_source_setscene

CLEANFUNCS += "deb_clean_source"

# Do not guard this with DEPLOY_DIR_SRC_LOCK: it runs from CLEANFUNCS, which also
# runs sstate_cleanall() taking that lock itself, and flock() would deadlock on
# the nested acquisition.
deb_clean_source() {
    repo_del_srcpackage "${REPO_ISAR_DIR}"/"${DISTRO}" \
        "${REPO_ISAR_DB_DIR}"/"${DISTRO}" "${DEBDISTRONAME}" "${DEBIAN_SOURCE}"
}

do_deploy_source[depends] += "isar-apt:do_cache_config"
do_deploy_source[lockfiles] = "${REPO_ISAR_DIR}/isar.lock ${DEPLOY_DIR_SRC_LOCK}"
do_deploy_source[dirs] = "${S} ${DEPLOY_DIR_SRC}"
do_deploy_source() {
    # Scan DEPLOY_DIR_SRC first. An empty directory means another multiconfig is
    # rebuilding this recipe: DEPLOY_DIR_SRC is transiently empty between
    # sstate_clean() and sstate_install() of its do_dpkg_source. Removing the
    # source from isar-apt and adding nothing back would drop it. Skipping is
    # safe: that multiconfig runs its own do_deploy_source once the rebuild
    # completed.
    DSC_FILE=$(find ${DEPLOY_DIR_SRC} -maxdepth 1 -name "${DEBIAN_SOURCE}_*.dsc")
    if [ -z "${DSC_FILE}" ]; then
        bbnote "${DEPLOY_DIR_SRC} is empty, leaving isar-apt untouched"
        return
    fi
    repo_del_srcpackage "${REPO_ISAR_DIR}"/"${DISTRO}" \
        "${REPO_ISAR_DB_DIR}"/"${DISTRO}" "${DEBDISTRONAME}" "${DEBIAN_SOURCE}"
    repo_add_srcpackage "${REPO_ISAR_DIR}"/"${DISTRO}" \
        "${REPO_ISAR_DB_DIR}"/"${DISTRO}" \
        "${DEBDISTRONAME}" \
        "${DSC_FILE}"
}
addtask deploy_source after do_dpkg_source

do_dpkg_build[depends] += "${BPN}:do_deploy_source"
# ensure that the source package is deployed into isar-apt
do_deploy_deb[rdepends] += "${BPN}:do_deploy_source"

SCHROOT_MOUNTS = "${WORKDIR}:/work ${REPO_ISAR_DIR}/${DISTRO}:/isar-apt"

fetch_common_source_schroot() {
    schroot_create_configs
    insert_mounts

    session_id=$(schroot -q -b -c ${SBUILD_CHROOT})
    echo "Started session: ${session_id}"

    schroot_cleanup() {
        schroot -q -f -e -c ${session_id} > /dev/null 2>&1
        remove_mounts > /dev/null 2>&1
        schroot_delete_configs
    }
    trap 'exit 1' INT HUP QUIT TERM ALRM USR1
    trap 'schroot_cleanup' EXIT

    E="${@ isar_export_proxies(d)}"

    schroot -r -c ${session_id} -d / -u root -- \
        apt-get update -o Dir::Etc::SourceList="sources.list.d/isar-apt.list" -o Dir::Etc::SourceParts="-" -o APT::Get::List-Cleanup="0"
    schroot -r -c ${session_id} -d / -- \
        sh -c '
            cd /work
            apt-get -y --download-only --only-source -o Debug::NoLocking=1 -o Acquire::Source-Symlinks="false" source ${DEBIAN_SOURCE}'

    schroot -e -c ${session_id}
    remove_mounts
    schroot_delete_configs
}

UNSHARE_DPKG_SOURCE_CHROOT = "${WORKDIR}/dpkg-source-chroot"
fetch_common_source_unshare() {
    run_privileged_heredoc <<'EOF'
        set -e
        mkdir -p ${UNSHARE_DPKG_SOURCE_CHROOT}
        tar -xf "${SBUILD_CHROOT}" -C ${UNSHARE_DPKG_SOURCE_CHROOT}

        ${@insert_isar_mounts(d, d.getVar('UNSHARE_DPKG_SOURCE_CHROOT'), d.getVar('SCHROOT_MOUNTS'))}
        chroot ${UNSHARE_DPKG_SOURCE_CHROOT} /bin/bash -s <<'EOAPT'
            set -e
            apt-get update \
                -o Dir::Etc::SourceList="sources.list.d/isar-apt.list" \
                -o Dir::Etc::SourceParts="-" \
                -o APT::Get::List-Cleanup="0"

            cd /work
            apt-get -y --download-only --only-source \
                -o Debug::NoLocking=1 -o Acquire::Source-Symlinks="false"  \
                source ${DEBIAN_SOURCE}
EOAPT
EOF

    # run cleanup in separate session to ensure nothing is mounted
    run_privileged rm -rf ${UNSHARE_DPKG_SOURCE_CHROOT}
}

do_fetch_common_source[depends] += "${SCHROOT_DEP} ${BPN}:do_deploy_source"
do_fetch_common_source[lockfiles] = "${REPO_ISAR_DIR}/isar.lock"
do_fetch_common_source[network] = "${TASK_USE_SUDO}"
do_fetch_common_source[depends] += "base-apt:do_cache isar-apt:do_cache_config"
do_fetch_common_source() {
    fetch_common_source_${ISAR_CHROOT_MODE}
}
addtask fetch_common_source

do_dpkg_build[depends] += "${@'${PN}:do_dpkg_source' if '${PN}' == '${BPN}' else '${PN}:do_fetch_common_source'}"
do_clean[depends] += "${@'' if '${PN}' == '${BPN}' else '${BPN}:do_clean'}"
