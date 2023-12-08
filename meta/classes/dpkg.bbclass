# This software is a part of ISAR.
# Copyright (C) 2015-2018 ilbers GmbH

inherit dpkg-base
inherit dpkg-source

# maximum time (in minutes for the build), override for packages requiring
# much more time (e.g. when cross-compiling isn't an option / supported and
# the package large)
DPKG_BUILD_TIMEOUT ?= "150"
dpkg_runbuild[vardepsexclude] += "${DPKG_BUILD_TIMEOUT}"

DPKG_PREBUILD_ENV_FILE="${WORKDIR}/dpkg_prebuild.env"

# bitbake variables that should be passed into sbuild env
# Note: must not have any logical influence on the generated package
SBUILD_PASSTHROUGH_ADDITIONS ?= ""

def expand_sbuild_pt_additions(d):
    cmds = ''
    for var in d.getVar('SBUILD_PASSTHROUGH_ADDITIONS').split():
        varval = d.getVar(var)
        if varval != None:
            cmds += 'sbuild_export ' + var + ' "' + varval + '"\n'
    return cmds

do_prepare_build:append() {
    env > ${DPKG_PREBUILD_ENV_FILE}
}

# cp -n results in nonzero exit code starting from coreutils 9.2
# and starting from 9.3 we can use --update=none for the same behaviour
CP_FLAGS ?= "-Ln --no-preserve=owner"
CP_FLAGS:sid ?= "-L --update=none --no-preserve=owner"

# Build package from sources using build script
dpkg_runbuild[vardepsexclude] += "${SBUILD_PASSTHROUGH_ADDITIONS}"
dpkg_runbuild() {
    E="${@ isar_export_proxies(d)}"
    E="${@ isar_export_ccache(d)}"
    export DEB_BUILD_OPTIONS="${@ isar_deb_build_options(d)}"
    export PARALLEL_MAKE="${PARALLEL_MAKE}"

    rm -f ${SBUILD_CONFIG}

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
        [ "${var}" = "CCACHE_DEBUGDIR" ] && continue
        [ "${var}" = "CCACHE_DEBUG" ] && continue
        [ "${var}" = "CCACHE_DISABLE" ] && continue
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
        [ "${var}" = "GIT_PROXY_COMMAND" ] && continue

        bbwarn "Export of '${line}' detected, please migrate to templates"
    done

    distro="${BASE_DISTRO}-${BASE_DISTRO_CODENAME}"
    if [ ${ISAR_CROSS_COMPILE} -eq 1 ]; then
        distro="${HOST_BASE_DISTRO}-${BASE_DISTRO_CODENAME}"
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
    ${@ expand_sbuild_pt_additions(d)}

    echo '$apt_keep_downloaded_packages = 1;' >> ${SBUILD_CONFIG}
    echo '$stalled_pkg_timeout = ${DPKG_BUILD_TIMEOUT};' >> ${SBUILD_CONFIG}

    DEB_SOURCE_NAME=$(dpkg-parsechangelog --show-field Source --file ${WORKDIR}/${PPS}/debian/changelog)
    DSC_FILE=$(find ${WORKDIR} -name "${DEB_SOURCE_NAME}*.dsc" -maxdepth 1 -print)

    sbuild -A -n -c ${SBUILD_CHROOT} --extra-repository="${ISAR_APT_REPO}" \
        --host=${PACKAGE_ARCH} --build=${BUILD_ARCH} ${profiles} \
        --no-run-lintian --no-run-piuparts --no-run-autopkgtest --resolve-alternatives \
        --bd-uninstallable-explainer=apt \
        --no-apt-update \
        --chroot-setup-commands="echo \"Package: *\nPin: release n=${DEBDISTRONAME}\nPin-Priority: 1000\" > /etc/apt/preferences.d/isar-apt" \
        --chroot-setup-commands="echo \"APT::Get::allow-downgrades 1;\" > /etc/apt/apt.conf.d/50isar-apt" \
        --chroot-setup-commands="rm -f /var/log/dpkg.log" \
        --chroot-setup-commands="mkdir -p ${deb_dir}" \
        --chroot-setup-commands="ln -sf ${ext_deb_dir}/*.deb -t ${deb_dir}/" \
        --finished-build-commands="rm -f ${deb_dir}/sbuild-build-depends-main-dummy_*.deb" \
        --finished-build-commands="[ -z "$(find ${deb_dir} -maxdepth 1 -name '*.deb' -print -quit)" ] || cp ${CP_FLAGS} ${deb_dir}/*.deb -t ${ext_deb_dir}/" \
        --finished-build-commands="cp /var/log/dpkg.log ${ext_root}/dpkg_partial.log" \
        --debbuildopts="--source-option=-I" \
        --build-dir=${WORKDIR} --dist="isar" ${DSC_FILE}

    sbuild_dpkg_log_export "${WORKDIR}/rootfs/dpkg_partial.log"
    deb_dl_dir_export "${WORKDIR}/rootfs" "${distro}"

    # Cleanup apt artifacts
    sudo rm -rf ${WORKDIR}/rootfs
}
