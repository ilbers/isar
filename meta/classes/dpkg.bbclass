# This software is a part of ISAR.
# Copyright (C) 2015-2018 ilbers GmbH

inherit dpkg-base

PACKAGE_ARCH ?= "${DISTRO_ARCH}"

# Install build dependencies for package
do_install_builddeps() {
    dpkg_do_mounts
    E="${@ isar_export_proxies(d)}"
    export DEB_BUILD_OPTIONS="${@ isar_deb_build_options(d)}"
    export DEB_BUILD_PROFILES="${@ isar_deb_build_profiles(d)}"
    distro="${DISTRO}"
    if [ ${ISAR_CROSS_COMPILE} -eq 1 ]; then
        distro="${HOST_DISTRO}"
    fi

    deb_dl_dir_import "${BUILDCHROOT_DIR}" "${distro}"
    sudo -E chroot ${BUILDCHROOT_DIR} /isar/deps.sh \
        ${PP}/${PPS} ${PACKAGE_ARCH} --download-only
    deb_dl_dir_export "${BUILDCHROOT_DIR}" "${distro}"
    sudo -E chroot ${BUILDCHROOT_DIR} /isar/deps.sh \
        ${PP}/${PPS} ${PACKAGE_ARCH}
    dpkg_undo_mounts
}

addtask install_builddeps after do_prepare_build before do_dpkg_build
do_install_builddeps[depends] += "${BUILDCHROOT_DEP} isar-apt:do_cache_config"
# apt and reprepro may not run in parallel, acquire the Isar lock
do_install_builddeps[lockfiles] += "${REPO_ISAR_DIR}/isar.lock"

addtask devshell after do_install_builddeps

DPKG_PREBUILD_ENV_FILE="${WORKDIR}/dpkg_prebuild.env"

do_prepare_build_append() {
    env > ${DPKG_PREBUILD_ENV_FILE}
}

# Build package from sources using build script
dpkg_runbuild() {
    E="${@ isar_export_proxies(d)}"
    E="${@ isar_export_ccache(d)}"
    export DEB_BUILD_OPTIONS="${@ isar_deb_build_options(d)}"
    export PARALLEL_MAKE="${PARALLEL_MAKE}"

    env | while read -r line; do
        # Filter the same lines
        grep -q "^${line}" ${DPKG_PREBUILD_ENV_FILE} && continue
        # Filter some standard variables
        echo ${line} | grep -q "^HOME=" && continue
        echo ${line} | grep -q "^PWD=" && continue

        var=$(echo "${line}" | cut -d '=' -f1)
        value=$(echo "${line}" | cut -d '=' -f2-)
        sbuild_export $var "$value"

        # Don't warn some variables
        [ "${var}" = "PARALLEL_MAKE" ] && continue
        [ "${var}" = "CCACHE_DIR" ] && continue
        [ "${var}" = "PATH_PREPEND" ] && continue
        [ "${var}" = "DEB_BUILD_OPTIONS" ] && continue

        bbwarn "Export of '${line}' detected, please migrate to templates"
    done

    profiles="${@ isar_deb_build_profiles(d)}"
    if [ ! -z "$profiles" ]; then
        profiles=$(echo --profiles="$profiles" | sed -e 's/ \+/,/g')
    fi

    export SBUILD_CONFIG="${SBUILD_CONFIG}"

    sbuild -A -n -c ${SBUILD_CHROOT} --extra-repository="${ISAR_APT_REPO}" \
        --host=${PACKAGE_ARCH} --build=${SBUILD_HOST_ARCH} ${profiles} \
        --no-run-lintian --no-run-piuparts --no-run-autopkgtest \
        --debbuildopts="--source-option=-I" \
        --build-dir=${WORKDIR} ${WORKDIR}/${PPS}
}
