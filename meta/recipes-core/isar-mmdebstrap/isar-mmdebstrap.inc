# Minimal debian root file system
#
# This software is a part of Isar.
# Copyright (C) 2024 ilbers GmbH
#
# SPDX-License-Identifier: MIT

inherit bootstrap
inherit compat
inherit deb-dl-dir

DISTRO_BOOTSTRAP_BASE_PACKAGES += "locales apt"
DISTRO_BOOTSTRAP_BASE_PACKAGES:append:https-support = " ca-certificates"

BOOTSTRAP_TMPDIR = "${WORKDIR}/tempdir"

# Fix for /var/lib/apt/available while maybe-jessie-or-older hook do not work
MM_HOOK_JESSIE = "/usr/share/mmdebstrap/hooks/jessie-or-older"
DPKG_HOOKS ?= "${@'--hook-dir='+d.getVar('MM_HOOK_JESSIE') \
              if os.path.isdir(d.getVar('MM_HOOK_JESSIE')) \
              else '--customize-hook=\'touch $1/var/lib/dpkg/available\''}"
MMHOOKS:focal ?= "${DPKG_HOOKS}"
MMHOOKS:buster ?= "${DPKG_HOOKS}"

DISTRO_BOOTSTRAP_KEYRING = "${WORKDIR}/distro-keyring.gpg"

def get_distro_have_https_source(d):
    return any(source[2].startswith("https://") for source in generate_distro_sources(d))

def get_distro_needs_https_support(d):
    if get_distro_have_https_source(d):
        return "https-support"
    else:
        return ""

OVERRIDES:append = ":${@get_distro_needs_https_support(d)}"

def get_apt_opts(d, param):
    opts = []
    retries = d.getVar('ISAR_APT_RETRIES') or "3"
    opts.append(f'Acquire::Retries="{retries}"')
    max_delay = d.getVar('ISAR_APT_DELAY_MAX')
    if max_delay:
        opts.append(f'Acquire::Retries::Delay::Maximum="{max_delay}"')
    dl_limit = d.getVar('ISAR_APT_DL_LIMIT')
    if dl_limit:
        opts.append(f'Acquire::http::Dl-Limit="{dl_limit}"')
        opts.append(f'Acquire::https::Dl-Limit="{dl_limit}"')
    return ' '.join([f'{param} {o}' for o in opts])

do_generate_keyrings[cleandirs] = "${WORKDIR}/trusted.gpg.d"
do_generate_keyrings[dirs] = "${DEBDIR}"
do_generate_keyrings[vardeps] += "DISTRO_BOOTSTRAP_KEYS THIRD_PARTY_APT_KEYS"
do_generate_keyrings[network] = "${TASK_USE_SUDO}"
do_generate_keyrings() {
    export GNUPGHOME="$(mktemp -td gpghomeXXXXXXXXXX)"
    if [ -n "${@d.getVar("THIRD_PARTY_APT_KEYFILES") or ""}" ]; then
        for keyfile in ${@d.getVar("THIRD_PARTY_APT_KEYFILES")}; do
           gpg --no-autostart --keyring "gnupg-ring:${DISTRO_BOOTSTRAP_KEYRING}" \
               --no-default-keyring --import $keyfile
        done
    fi
    if [ -n "${@d.getVar("DISTRO_BOOTSTRAP_KEYFILES") or ""}" ]; then
        for keyfile in ${@d.getVar("DISTRO_BOOTSTRAP_KEYFILES")}; do
           gpg --no-autostart --keyring "gnupg-ring:${DISTRO_BOOTSTRAP_KEYRING}" \
               --no-default-keyring --import $keyfile
        done
    fi
    if [ -r "${DISTRO_BOOTSTRAP_KEYRING}" ]; then
        chmod o+r "${DISTRO_BOOTSTRAP_KEYRING}"
    fi
}
addtask generate_keyrings before do_build after do_unpack

# Generate an apt configuration file holding credentials for the apt sources
# requiring user authentication
do_generate_auth_file[vardeps] += "ISAR_APT_CREDS"
python do_generate_auth_file() {
    creds = d.getVar('ISAR_APT_CREDS') or ''
    auth_file = os.path.join(d.getVar('WORKDIR'), 'apt-auth')
    if not creds:
        if os.path.exists(auth_file):
            os.unlink(auth_file)
        return

    with open(auth_file, "w") as f:
        for machine in creds.split():
            user_password = d.getVar(f"ISAR_APT_CREDS_{machine}")
            try:
                user, passwd = user_password.split()
                f.write(f"machine {machine}\n"
                        f"  user {user}\n"
                        f"  password {passwd}\n")
            except ValueError:
                bb.fatal(f"Too few/many tokens in ISAR_APT_CREDS['{machine}']: "
                         f"user and password expected (got '{user_password}')!")
}
addtask generate_auth_file before do_bootstrap after do_unpack

def get_apt_auth_opts(d):
    creds = d.getVar('ISAR_APT_CREDS') or ''
    workdir = d.getVar('WORKDIR')
    if creds:
        return "--setup-hook='mkdir -p \"$1/etc/apt/auth.conf.d\"' " + \
               f"--setup-hook='upload \"{workdir}/apt-auth\" /etc/apt/auth.conf.d/isar.conf'"
    return ''

do_bootstrap[vardeps] += " \
    DISTRO_APT_PREMIRRORS \
    ISAR_ENABLE_COMPAT_ARCH \
    ${DISTRO_VARS_PREFIX}DISTRO_APT_SOURCES \
    "
do_bootstrap[dirs] = "${DEPLOY_DIR_BOOTSTRAP} ${BOOTSTRAP_TMPDIR} ${WORKDIR}/trusted.gpg.d ${WORKDIR}/sources.list.d"
do_bootstrap[depends] = "base-apt:do_cache isar-apt:do_cache_config"
do_bootstrap[network] = "${TASK_USE_NETWORK_AND_SUDO}"

DEB_DL_LOCK ?= "${DEBDIR}/${BOOTSTRAP_BASE_DISTRO}-${BASE_DISTRO_CODENAME}.lock"

do_bootstrap[vardeps] += "DISTRO_BOOTSTRAP_BASE_PACKAGES"
do_bootstrap() {
    if [ "${ISAR_ENABLE_COMPAT_ARCH}" = "1" ]; then
        if [ -z "${COMPAT_DISTRO_ARCH}" ]; then
            bbfatal "${DISTRO_ARCH} does not have a compat arch"
        fi
    fi
    bootstrap_args="--verbose --variant=minbase --include=${@','.join(d.getVar('DISTRO_BOOTSTRAP_BASE_PACKAGES').split())}"
    if [ -f "${DISTRO_BOOTSTRAP_KEYRING}" ]; then
        bootstrap_args="$bootstrap_args --keyring=${DISTRO_BOOTSTRAP_KEYRING}"
        cp "${DISTRO_BOOTSTRAP_KEYRING}" "${WORKDIR}/trusted.gpg.d/"
    fi
    E="${@ isar_export_proxies(d)}"

    if [ "${ISAR_USE_CACHED_BASE_REPO}" = "1" ]; then
        base_apt_tmp="$(mktemp -d /tmp/isar-base-aptXXXXXXXXXX)"
        bootstrap_list="${WORKDIR}/sources.list.d/base-apt.list"
        line="copy://$base_apt_tmp/${BOOTSTRAP_BASE_DISTRO} ${BASE_DISTRO_CODENAME} main"
        if [ -z "${BASE_REPO_KEY}" ]; then
            line="[trusted=yes] ${line}"
        fi
        echo "deb ${line}" >  "${WORKDIR}/sources.list.d/base-apt.list"
        line="copy://$base_apt_tmp/${BASE_DISTRO} ${BASE_DISTRO_CODENAME} main"
        if [ -z "${BASE_REPO_KEY}" ]; then
            line="[trusted=yes] ${line}"
        fi
        echo "deb-src ${line}" >>  "${WORKDIR}/sources.list.d/base-apt.list"

        # no need to sync /var/cache/apt/archives if base-apt used
        syncin='echo skip sync-in'
        syncout='echo skip sync-out'
        extra_setup="mount --bind '${REPO_BASE_DIR}' $base_apt_tmp"
        extra_extract="$syncout"
        # save mmdebstrap tempdir for cleanup
        extra_essential="mkdir -p \$1/$base_apt_tmp && \
                         echo \$1 > ${WORKDIR}/mmtmpdir && \
                         mount -o bind,private '${REPO_BASE_DIR}' \$1/$base_apt_tmp"
        # replace base-apt mount in tmp with /base-apt mount
        extra_customize="sed -i \"s|copy://$base_apt_tmp|file:///base-apt|g\" \
                             \$1/etc/apt/sources.list.d/*.list && \
                         mkdir -p \$1/base-apt && \
                         mount -o bind,private '${REPO_BASE_DIR}' \$1/base-apt && \
                         chroot \$1 apt-get update -y \
                                -o APT::Update::Error-Mode=any && \
                         chroot \$1 apt-get install -y dpkg && \
                         umount \$1/base-apt && \
                         umount \$1/$base_apt_tmp && rm ${WORKDIR}/mmtmpdir && \
                         umount $base_apt_tmp && rm -rf --one-file-system $base_apt_tmp"
    else
        deb_dl_dir_import "${WORKDIR}/dl_dir" "${BOOTSTRAP_BASE_DISTRO}-${BASE_DISTRO_CODENAME}"

        bootstrap_list="${WORKDIR}/sources.list.d/bootstrap.list"
        install -v -m644 "${APTSRCS}" \
                         "${WORKDIR}/sources.list.d/bootstrap.list"

        syncin='flock -s ${DEB_DL_LOCK} cp -n --no-preserve=owner \
                      "${WORKDIR}/dl_dir/var/cache/apt/archives/"*.deb \
                      "$1/var/cache/apt/archives/" || true'
        syncout='flock -s ${DEB_DL_LOCK} cp -n --no-preserve=owner \
                       "$1/var/cache/apt/archives/"*.deb \
                       "${WORKDIR}/dl_dir/var/cache/apt/archives/"'
        extra_setup="$syncin"
        extra_extract="$syncout"
        # prefetch apt debs because mmdebstrap will clean them on next stage
        extra_essential='apt-get install apt -y -d \
                                 -o Dir::State="$1/var/lib/apt" \
                                 -o Dir::Etc="$1/etc/apt" \
                                 -o Dir::Cache="$1/var/cache/apt" \
                                 -o Apt::Architecture="${BOOTSTRAP_DISTRO_ARCH}" \
                                 ${@get_apt_opts(d, '-o')}'
        extra_essential="$extra_essential && $syncout"
        extra_customize="$syncout"
    fi

    if [ ! -z "${SOURCE_DATE_EPOCH}" ]; then
        export SOURCE_DATE_EPOCH="${SOURCE_DATE_EPOCH}"
    fi

    arch_param="--arch=${BOOTSTRAP_DISTRO_ARCH},${DISTRO_ARCH}"
    if [ "${ISAR_ENABLE_COMPAT_ARCH}" = "1" ]; then
        arch_param="$arch_param,${COMPAT_DISTRO_ARCH}"
    fi

    # Cleanup mounts if fails
    trap 'exit 1' INT HUP QUIT TERM ALRM USR1
    trap '[ -r "${WORKDIR}/mmtmpdir" ] && tmpdir=$(cat "${WORKDIR}/mmtmpdir") \
                                       && rm "${WORKDIR}/mmtmpdir"; \
          [ -d "$tmpdir" ] && mountpoint -q $tmpdir/$base_apt_tmp \
                           && sudo umount $tmpdir/$base_apt_tmp; \
          [ -d "$tmpdir" ] && mountpoint -q $tmpdir/base-apt \
                           && sudo umount $tmpdir/base-apt; \
          [ -d "$tmpdir" ] && sudo rm -rf --one-file-system $tmpdir; \
          [ -n "$base_apt_tmp" ] && mountpoint -q $base_apt_tmp \
                                 && sudo umount $base_apt_tmp \
                                 && rm -rf --one-file-system $base_apt_tmp' EXIT

    # Create lock file so that it is owned by the user running the build (not root)
    mkdir -p ${DEBDIR}
    touch ${DEB_DL_LOCK}

    sudo TMPDIR="${BOOTSTRAP_TMPDIR}" mmdebstrap $bootstrap_args \
                   $arch_param \
                   --mode=unshare \
                   ${MMHOOKS} \
                   ${@get_apt_auth_opts(d)} \
                   --setup-hook='mkdir -p "$1/var/cache/apt/archives/"' \
                   --setup-hook="$extra_setup" \
                   --setup-hook='upload "${APTPREFS}" /etc/apt/preferences.d/bootstrap' \
                   --setup-hook='upload "${APTSRCS_INIT}" /etc/apt/sources-list' \
                   --setup-hook='upload "${WORKDIR}/locale" /etc/locale' \
                   --setup-hook='mkdir -p "$1/etc/apt/trusted.gpg.d"' \
                   --setup-hook='sync-in "${WORKDIR}/trusted.gpg.d" /etc/apt/trusted.gpg.d' \
                   --setup-hook='install -v -m755 "${WORKDIR}/chroot-setup.sh" "$1/chroot-setup.sh"' \
                   --extract-hook="$extra_extract" \
                   --essential-hook="$extra_essential" \
                   --customize-hook="$extra_customize" \
                   --customize-hook='sed -i "/en_US.UTF-8 UTF-8/s/^#//g" "$1/etc/locale.gen"' \
                   --customize-hook='chroot "$1" /usr/sbin/locale-gen' \
                   --customize-hook='chroot "$1" /usr/bin/apt-get -y clean' \
                   --skip=cleanup/apt \
                   --skip=download/empty \
                   ${@get_apt_opts(d, '--aptopt')} \
                   ${@get_distro_components_argument(d)} \
                   "${@get_distro_suite(d)}" \
                   "${WORKDIR}/rootfs.tar.zst" \
                   "$bootstrap_list"

    # Finalize bootstrap by setting the link in deploy
    sudo ln -Tfsr "${WORKDIR}/rootfs.tar.zst" "${DEPLOY_ISAR_BOOTSTRAP}.tar.zst"

    if [ "${ISAR_USE_CACHED_BASE_REPO}" != "1" ]; then
        deb_dl_dir_export "${WORKDIR}/dl_dir" "${BOOTSTRAP_BASE_DISTRO}-${BASE_DISTRO_CODENAME}"
        sudo rm -rf --one-file-system "${WORKDIR}/dl_dir"
    fi
}
addtask bootstrap before do_build after do_generate_keyrings

SSTATETASKS += "do_bootstrap"
SSTATECREATEFUNCS += "bootstrap_sstate_prepare"
SSTATEPOSTINSTFUNCS += "bootstrap_sstate_finalize"

bootstrap_sstate_prepare() {
    # this runs in SSTATE_BUILDDIR, which will be deleted automatically
    sudo cp -a "${WORKDIR}/rootfs.tar.zst" ./bootstrap.tar.zst
    sudo chown $(id -u):$(id -g) bootstrap.tar.zst
}

bootstrap_sstate_finalize() {
    # this runs in SSTATE_INSTDIR
    # we should restore symlinks after using tar
    if [ -f bootstrap.tar.zst ]; then
        mv bootstrap.tar.zst "${WORKDIR}/rootfs.tar.zst"
        sudo ln -Tfsr "${WORKDIR}/rootfs.tar.zst" \
                      "${DEPLOY_ISAR_BOOTSTRAP}.tar.zst"
    fi
}

python do_bootstrap_setscene() {
    sstate_setscene(d)
}

addtask do_bootstrap_setscene
do_bootstrap_setscene[dirs] = "${DEPLOY_DIR_BOOTSTRAP}"
