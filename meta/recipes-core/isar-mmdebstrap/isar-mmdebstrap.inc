# Minimal debian root file system
#
# This software is a part of Isar.
# Copyright (C) 2024 ilbers GmbH
#
# SPDX-License-Identifier: MIT

inherit bootstrap
inherit compat
inherit deb-dl-dir

FILESEXTRAPATHS:append = ":${LAYERDIR_core}/recipes-core/isar-bootstrap/files"

ROOTFSDIR = "${WORKDIR}/rootfs"
DISTRO_BOOTSTRAP_BASE_PACKAGES = "locales,apt,usrmerge"
DISTRO_BOOTSTRAP_BASE_PACKAGES:append:gnupg = ",gnupg"
DISTRO_BOOTSTRAP_BASE_PACKAGES:append:https-support = ",ca-certificates"
BOOTSTRAP_TMPDIR = "${WORKDIR}/tempdir"

# Fix for /var/lib/apt/available while maybe-jessie-or-older hook do not work
MM_HOOK_JESSIE = "/usr/share/mmdebstrap/hooks/jessie-or-older"
DPKG_HOOKS ?= "${@'--hook-dir='+d.getVar('MM_HOOK_JESSIE') \
              if os.path.isdir(d.getVar('MM_HOOK_JESSIE')) \
              else '--customize-hook=\'touch /var/lib/dpkg/available\''}"
MMHOOKS:ubuntu-focal ?= "${DPKG_HOOKS}"
MMHOOKS:debian-buster ?= "${DPKG_HOOKS}"

def get_distro_primary_source_entry(d):
    for source in generate_distro_sources(d):
        if source[0] == "deb":
            return source[2:]
    bb.fatal('Invalid apt sources list')

def get_distro_have_https_source(d):
    return any(source[2].startswith("https://") for source in generate_distro_sources(d))

def get_distro_needs_https_support(d):
    if get_distro_have_https_source(d):
        return "https-support"
    else:
        return ""

OVERRIDES:append = ":${@get_distro_needs_https_support(d)}"

def get_distro_needs_gpg_support(d):
    if d.getVar("DISTRO_BOOTSTRAP_KEYS") or \
       d.getVar("THIRD_PARTY_APT_KEYS") or \
       d.getVar("BASE_REPO_KEY"):
        return "gnupg"
    else:
        return ""

OVERRIDES:append = ":${@get_distro_needs_gpg_support(d)}"

APT_KEYS_DIR = "${WORKDIR}/aptkeys"
DISTRO_BOOTSTRAP_KEYRING = "${WORKDIR}/distro-keyring.gpg"

do_generate_keyrings[cleandirs] = "${APT_KEYS_DIR}"
do_generate_keyrings[dirs] = "${DL_DIR}"
do_generate_keyrings[vardeps] += "DISTRO_BOOTSTRAP_KEYS THIRD_PARTY_APT_KEYS"
do_generate_keyrings[network] = "${TASK_USE_SUDO}"
do_generate_keyrings() {
    if [ -n "${@d.getVar("THIRD_PARTY_APT_KEYFILES") or ""}" ]; then
        chmod 777 "${APT_KEYS_DIR}"
        for keyfile in ${@d.getVar("THIRD_PARTY_APT_KEYFILES")}; do
           cp "$keyfile" "${APT_KEYS_DIR}"/"$(basename "$keyfile")"
        done
    fi
    if [ -n "${@d.getVar("DISTRO_BOOTSTRAP_KEYFILES") or ""}" ]; then
        for keyfile in ${@d.getVar("DISTRO_BOOTSTRAP_KEYFILES")}; do
           sudo apt-key --keyring "${DISTRO_BOOTSTRAP_KEYRING}" add $keyfile
           cp "$keyfile" "${APT_KEYS_DIR}"/"$(basename "$keyfile")"
        done
    fi
}
addtask generate_keyrings before do_build after do_unpack

do_bootstrap[vardeps] += " \
    DISTRO_APT_PREMIRRORS \
    ISAR_ENABLE_COMPAT_ARCH \
    ${DISTRO_VARS_PREFIX}DISTRO_APT_SOURCES \
    "
do_bootstrap[dirs] = "${DEPLOY_DIR_BOOTSTRAP} ${BOOTSTRAP_TMPDIR}"
do_bootstrap[depends] = "base-apt:do_cache isar-apt:do_cache_config"
do_bootstrap[network] = "${TASK_USE_NETWORK_AND_SUDO}"

do_bootstrap() {
    if [ "${ISAR_ENABLE_COMPAT_ARCH}" = "1" ]; then
        if [ -z "${COMPAT_DISTRO_ARCH}" ]; then
            bbfatal "${DISTRO_ARCH} does not have a compat arch"
        fi
    fi
    bootstrap_args="--verbose --variant=minbase --include=${DISTRO_BOOTSTRAP_BASE_PACKAGES}"
    if [ -f "${DISTRO_BOOTSTRAP_KEYRING}" ]; then
        bootstrap_args="$bootstrap_args --keyring=${DISTRO_BOOTSTRAP_KEYRING}"
    fi
    E="${@ isar_export_proxies(d)}"
    export BOOTSTRAP_FOR_HOST

    deb_dl_dir_import "${ROOTFSDIR}" "${BOOTSTRAP_BASE_DISTRO}-${BASE_DISTRO_CODENAME}"
    sudo rm -rf --one-file-system "${ROOTFSDIR}"
    mkdir -p "${ROOTFSDIR}"

    arch_param="--arch=${BOOTSTRAP_DISTRO_ARCH},${DISTRO_ARCH}"

    sudo TMPDIR="${BOOTSTRAP_TMPDIR}" mmdebstrap $bootstrap_args \
                   $arch_param \
                   --mode=unshare \
                   ${MMHOOKS} \
                   ${@get_distro_components_argument(d)} \
                   "${@get_distro_suite(d)}" \
                   "${WORKDIR}/rootfs.tar.zst" \
                   "${@get_distro_source(d)}"

    sudo -E -s <<'EOSUDO'
        set -e

        tar -xf "${WORKDIR}/rootfs.tar.zst" -C "${ROOTFSDIR}" --exclude="./dev/console"

        # Install apt config
        mkdir -p "${ROOTFSDIR}/etc/apt/preferences.d"
        install -v -m644 "${APTPREFS}" \
                         "${ROOTFSDIR}/etc/apt/preferences.d/bootstrap"
        mkdir -p "${ROOTFSDIR}/etc/apt/sources.list.d"
        if [ "${ISAR_USE_CACHED_BASE_REPO}" = "1" ]; then
            line="file:///base-apt/${BOOTSTRAP_BASE_DISTRO} ${BASE_DISTRO_CODENAME} main"
            if [ -z "${BASE_REPO_KEY}" ]; then
                line="[trusted=yes] ${line}"
            fi
            echo "deb ${line}" >  "${ROOTFSDIR}/etc/apt/sources.list.d/base-apt.list"
            line="file:///base-apt/${BASE_DISTRO} ${BASE_DISTRO_CODENAME} main"
            if [ -z "${BASE_REPO_KEY}" ]; then
                line="[trusted=yes] ${line}"
            fi
            echo "deb-src ${line}" >>  "${ROOTFSDIR}/etc/apt/sources.list.d/base-apt.list"

            mkdir -p ${ROOTFSDIR}/base-apt
            mount -o bind,private ${REPO_BASE_DIR} ${ROOTFSDIR}/base-apt
        else
            install -v -m644 "${APTSRCS}" \
                             "${ROOTFSDIR}/etc/apt/sources.list.d/bootstrap.list"
        fi
        install -v -m644 "${APTSRCS_INIT}" "${ROOTFSDIR}/etc/apt/sources-list"
        rm -f "${ROOTFSDIR}/etc/apt/sources.list"
        rm -rf "${ROOTFSDIR}/var/lib/apt/lists/"*
        find ${APT_KEYS_DIR}/ -type f | while read keyfile
        do
            MY_GPGHOME="$(chroot "${ROOTFSDIR}" mktemp -d /tmp/gpghomeXXXXXXXXXX)"
            echo "Created temporary directory ${MY_GPGHOME} for gpg-agent"
            export GNUPGHOME="${MY_GPGHOME}"
            APT_KEY_APPEND="--homedir ${MY_GPGHOME}"

            kfn="$(basename $keyfile)"
            cp $keyfile "${ROOTFSDIR}/tmp/$kfn"
            chroot "${ROOTFSDIR}" /usr/bin/gpg-agent --daemon -- /usr/bin/apt-key \
                --keyring ${THIRD_PARTY_APT_KEYRING} ${APT_KEY_APPEND} add "/tmp/$kfn"
            rm "${ROOTFSDIR}/tmp/$kfn"

            echo "Removing ${MY_GPGHOME}"
            rm -rf "${ROOTFSDIR}${MY_GPGHOME}"
        done

        # Set locale
        install -v -m644 "${WORKDIR}/locale" "${ROOTFSDIR}/etc/locale"

        sed -i '/en_US.UTF-8 UTF-8/s/^#//g' "${ROOTFSDIR}/etc/locale.gen"
        chroot "${ROOTFSDIR}" /usr/sbin/locale-gen

        # update APT
        mount -o bind,private /dev ${ROOTFSDIR}/dev
        mount -o bind,private /dev/pts ${ROOTFSDIR}/dev/pts
        mount -t tmpfs none "${ROOTFSDIR}/dev/shm"
        mount -t proc none ${ROOTFSDIR}/proc
        mount -o bind,private /sys ${ROOTFSDIR}/sys
        mount --make-rslave ${ROOTFSDIR}/sys

        export DEBIAN_FRONTEND=noninteractive

        if [ "${BOOTSTRAP_FOR_HOST}" = "1" ]; then
            chroot "${ROOTFSDIR}" /usr/bin/dpkg --add-architecture ${DISTRO_ARCH}
        fi

        if [ "${ISAR_ENABLE_COMPAT_ARCH}" = "1" ]; then
            chroot "${ROOTFSDIR}" /usr/bin/dpkg --add-architecture ${COMPAT_DISTRO_ARCH}
        fi

        chroot "${ROOTFSDIR}" /usr/bin/apt-get update -y \
                                -o APT::Update::Error-Mode=any

        chroot "${ROOTFSDIR}" /usr/bin/apt-get install -y dpkg

        # setup chroot
        install -v -m755 "${WORKDIR}/chroot-setup.sh" "${ROOTFSDIR}/chroot-setup.sh"
        "${ROOTFSDIR}/chroot-setup.sh" "setup" "${ROOTFSDIR}"

        chroot "${ROOTFSDIR}" /usr/bin/apt-get install -y -f
        chroot "${ROOTFSDIR}" /usr/bin/apt-get dist-upgrade -y \
                                -o Debug::pkgProblemResolver=yes

        umount "${ROOTFSDIR}/dev/shm"
        umount "${ROOTFSDIR}/dev/pts"
        umount "${ROOTFSDIR}/dev"
        umount "${ROOTFSDIR}/proc"
        umount "${ROOTFSDIR}/sys"
        if mountpoint -q "${ROOTFSDIR}/base-apt"; then
            umount "${ROOTFSDIR}/base-apt"
        fi

        # Finalize bootstrap by setting the link in deploy
        ln -Tfsr "${ROOTFSDIR}" "${DEPLOY_ISAR_BOOTSTRAP}"
EOSUDO
    deb_dl_dir_export "${ROOTFSDIR}" "${BOOTSTRAP_BASE_DISTRO}-${BASE_DISTRO_CODENAME}"

    # Cleanup apt cache
    sudo -Es chroot "${ROOTFSDIR}" /usr/bin/apt-get -y clean
}
addtask bootstrap before do_build after do_generate_keyrings

SSTATETASKS += "do_bootstrap"
SSTATECREATEFUNCS += "bootstrap_sstate_prepare"
SSTATEPOSTINSTFUNCS += "bootstrap_sstate_finalize"

bootstrap_sstate_prepare() {
    # this runs in SSTATE_BUILDDIR, which will be deleted automatically
    sudo cp -a "$(dirname "${ROOTFSDIR}")/rootfs.tar.zst" ./bootstrap.tar.zst
    sudo chown $(id -u):$(id -g) bootstrap.tar.zst
}

bootstrap_sstate_finalize() {
    # this runs in SSTATE_INSTDIR
    # we should restore symlinks after using tar
    if [ -f bootstrap.tar.zst ]; then
        mv bootstrap.tar.zst "$(dirname "${ROOTFSDIR}")/rootfs.tar.zst"
        sudo ln -Tfsr "$(dirname "${ROOTFSDIR}")/rootfs.tar.zst" \
                      "${DEPLOY_ISAR_BOOTSTRAP}.tar.zst"
    fi
}

python do_bootstrap_setscene() {
    sstate_setscene(d)
}

addtask do_bootstrap_setscene
do_bootstrap_setscene[dirs] = "${DEPLOY_DIR_BOOTSTRAP}"
