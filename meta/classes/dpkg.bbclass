# This software is a part of ISAR.
# Copyright (C) 2015-2018 ilbers GmbH

inherit dpkg-base

PACKAGE_ARCH ?= "${DISTRO_ARCH}"

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

        [ "${var}" = "http_proxy" ] && continue
        [ "${var}" = "HTTP_PROXY" ] && continue
        [ "${var}" = "https_proxy" ] && continue
        [ "${var}" = "HTTPS_PROXY" ] && continue
        [ "${var}" = "ftp_proxy" ] && continue
        [ "${var}" = "FTP_PROXY" ] && continue
        [ "${var}" = "no_proxy" ] && continue
        [ "${var}" = "NO_PROXY" ] && continue

        bbwarn "Export of '${line}' detected, please migrate to templates"
    done

    distro="${DISTRO}"
    if [ ${ISAR_CROSS_COMPILE} -eq 1 ]; then
        distro="${HOST_DISTRO}"
    fi

    deb_dl_dir_import "${WORKDIR}/rootfs" "${distro}"

    deb_dir="/var/cache/apt/archives"
    ext_root="${PP}/rootfs"
    ext_deb_dir="${ext_root}${deb_dir}"

    if [ ${USE_CCACHE} -eq 1 ]; then
        schroot_configure_ccache
    fi

    profiles="${@ isar_deb_build_profiles(d)}"
    if [ ! -z "$profiles" ]; then
        profiles=$(echo --profiles="$profiles" | sed -e 's/ \+/,/g')
    fi

    export SBUILD_CONFIG="${SBUILD_CONFIG}"

    for envvar in http_proxy HTTP_PROXY https_proxy HTTPS_PROXY \
        ftp_proxy FTP_PROXY no_proxy NO_PROXY; do
        sbuild_add_env_filter "$envvar"
    done

    echo '$apt_keep_downloaded_packages = 1;' >> ${SBUILD_CONFIG}

    # Create a .dsc file from source directory to use it with sbuild
    sh -c "cd ${WORKDIR}; dpkg-source -q -b ${PPS}"
    DSC=$(head -n1 ${WORKDIR}/${PPS}/debian/changelog | awk '{gsub(/[()]/,""); printf "%s_%s.dsc", $1, $2}')

    sbuild -A -n -c ${SBUILD_CHROOT} --extra-repository="${ISAR_APT_REPO}" \
        --host=${PACKAGE_ARCH} --build=${SBUILD_HOST_ARCH} ${profiles} \
        --no-run-lintian --no-run-piuparts --no-run-autopkgtest \
        --chroot-setup-commands="rm -f /var/log/dpkg.log" \
        --chroot-setup-commands="cp -n --no-preserve=owner ${ext_deb_dir}/*.deb -t ${deb_dir}/ || :" \
        --finished-build-commands="rm -f ${deb_dir}/sbuild-build-depends-main-dummy_*.deb" \
        --finished-build-commands="cp -n --no-preserve=owner ${deb_dir}/*.deb -t ${ext_deb_dir}/ || :" \
        --finished-build-commands="cp /var/log/dpkg.log ${ext_root}/dpkg_partial.log" \
        --debbuildopts="--source-option=-I" \
        --build-dir=${WORKDIR} --dist="isar" ${WORKDIR}/${DSC}

    sbuild_dpkg_log_export "${WORKDIR}/rootfs/dpkg_partial.log"
    deb_dl_dir_export "${WORKDIR}/rootfs" "${distro}"

    # Cleanup apt artifacts
    sudo rm -rf ${WORKDIR}/rootfs
}
