# This software is a part of Isar.
# Copyright (C) 2024 ilbers GmbH
#
# SPDX-License-Identifier: MIT

# Prefetch to base-apt repo by default
ISAR_PREFETCH_BASE_APT ??= "1"

DEBREPO_WORKDIR ??= "${DEBREPO_TARGET_DIR}"

debrepo_update_apt_source_list() {
    [ "${ISAR_PREFETCH_BASE_APT}" != "1" ] && return

    chroot_dir=${1}
    apt_list=${2}

    flock -x "${REPO_BASE_DIR}/repo.lock" -c "
        sudo -E chroot ${chroot_dir} /usr/bin/apt-get update \
            -o Dir::Etc::SourceList=\"sources.list.d/${apt_list}.list\" \
            -o Dir::Etc::SourceParts=\"-\" \
            -o APT::Get::List-Cleanup=\"0\"
    "
}

debrepo_add_packages() {
    [ "${ISAR_PREFETCH_BASE_APT}" != "1" ] && return
    [ "${ISAR_USE_CACHED_BASE_REPO}" = "1" ] && return

    args=""
    if [ "${1}" = "--srcmode" ]; then
        args="${args} --srcmode"
        shift
    fi

    if [ "${1}" = "--isarapt" ]; then
        args="${args} --extrarepo=${REPO_ISAR_DIR}/${DISTRO}"
        shift
    fi

    workdir="${1}"
    args="${args} ${2}"

    if [ -n "${GNUPGHOME}" ]; then
        export GNUPGHOME="${GNUPGHOME}"
    else
        export GNUPGHOME="${WORKDIR}/gpghome"
    fi

    ${SCRIPTSDIR}/debrepo \
        --workdir="${workdir}" \
        ${args}
}

debrepo_parse_dscfile() {
    [ "${ISAR_PREFETCH_BASE_APT}" != "1" ] && return
    [ "${ISAR_USE_CACHED_BASE_REPO}" = "1" ] && return

    dscfile="${1}"
    args=""

    build_arch=${DISTRO_ARCH}
    if [ "${ISAR_CROSS_COMPILE}" = "1" ]; then
        build_arch=${HOST_ARCH}
    fi
    if [ "${PACKAGE_ARCH}" != "${build_arch}" ]; then
        args="--crossbuild \
            crossbuild-essential-${PACKAGE_ARCH}:${build_arch} \
            dose-distcheck:${build_arch} \
            libc-dev:${PACKAGE_ARCH} \
            libstdc++-dev:${PACKAGE_ARCH} \
        "
    fi

    args="${args} --extrarepo=${WORKDIR}/isar-apt/${DISTRO}-${DISTRO_ARCH}/apt/${DISTRO}"

    if [ -n "${GNUPGHOME}" ]; then
        export GNUPGHOME="${GNUPGHOME}"
    else
        export GNUPGHOME="${WORKDIR}/gpghome"
    fi

    if [ -n "${DEB_BUILD_PROFILES}" ]; then
        export DEB_BUILD_PROFILES="${DEB_BUILD_PROFILES}"
    fi

    ${SCRIPTSDIR}/debrepo \
        --workdir="${DEBREPO_WORKDIR}" \
        --dscfile="${dscfile}" \
        ${args}
}
