# Minimal debian root file system
#
# This software is a part of ISAR.
# Copyright (c) Siemens AG, 2018-2021
#
# SPDX-License-Identifier: MIT

LICENSE = "gpl-2.0"
LIC_FILES_CHKSUM = "file://${LAYERDIR_core}/licenses/COPYING.GPLv2;md5=751419260aa954499f7abaabaa882bbe"
FILESPATH:prepend := "${THISDIR}/files:"
SRC_URI = " \
    file://locale \
    file://chroot-setup.sh"
PV = "1.0"

BOOTSTRAP_FOR_HOST ?= "0"

APTPREFS = "${WORKDIR}/apt-preferences"
APTSRCS = "${WORKDIR}/apt-sources"
APTSRCS_INIT = "${WORKDIR}/apt-sources-init"
DISTRO_BOOTSTRAP_KEYFILES = ""
THIRD_PARTY_APT_KEYFILES = ""
DEPLOY_ISAR_BOOTSTRAP ?= ""
DISTRO_BOOTSTRAP_BASE_PACKAGES = "locales,usrmerge"
DISTRO_BOOTSTRAP_BASE_PACKAGES:append:ubuntu = ",apt"
DISTRO_BOOTSTRAP_BASE_PACKAGES:append:raspios = ",apt"
DISTRO_BOOTSTRAP_BASE_PACKAGES:append:raspios64 = ",apt"
DISTRO_VARS_PREFIX ?= "${@'HOST_' if bb.utils.to_boolean(d.getVar('BOOTSTRAP_FOR_HOST')) else ''}"
BOOTSTRAP_DISTRO = "${@d.getVar('HOST_DISTRO' if bb.utils.to_boolean(d.getVar('BOOTSTRAP_FOR_HOST')) else 'DISTRO')}"
BOOTSTRAP_BASE_DISTRO = "${@d.getVar('HOST_BASE_DISTRO' if bb.utils.to_boolean(d.getVar('BOOTSTRAP_FOR_HOST')) else 'BASE_DISTRO')}"
BOOTSTRAP_DISTRO_ARCH = "${@d.getVar('HOST_ARCH' if d.getVar('BOOTSTRAP_FOR_HOST') == '1' else 'DISTRO_ARCH')}"
BOOTSTRAP_TMPDIR = "${WORKDIR}/tempdir"
FILESEXTRAPATHS:append = ":${BBPATH}"

inherit deb-dl-dir

# Fix for /var/lib/apt/available while maybe-jessie-or-older hook do not work
MM_HOOK_JESSIE = "/usr/share/mmdebstrap/hooks/jessie-or-older"
DPKG_HOOKS ?= "${@'--hook-dir='+d.getVar('MM_HOOK_JESSIE') \
              if os.path.isdir(d.getVar('MM_HOOK_JESSIE')) \
              else '--customize-hook=\'touch /var/lib/dpkg/available\''}"
MMHOOKS:ubuntu-focal ?= "${DPKG_HOOKS}"
MMHOOKS:debian-buster ?= "${DPKG_HOOKS}"

def get_distro_suite(d):
    return get_distro_primary_source_entry(d)[1]

python () {
    distro_bootstrap_keys = (d.getVar("DISTRO_BOOTSTRAP_KEYS") or "").split()
    third_party_apt_keys = (d.getVar("THIRD_PARTY_APT_KEYS") or "").split()
    topdir = d.getVar("TOPDIR")

    # The cached repo key can be both for bootstrapping and apt package
    # installation afterwards. However, bootstrap will include the key into
    # the rootfs automatically thus the right place is distro_bootstrap_keys.

    if bb.utils.to_boolean(d.getVar('ISAR_USE_CACHED_BASE_REPO')):
        own_pub_key = d.getVar("BASE_REPO_KEY")
        if own_pub_key:
            distro_bootstrap_keys += own_pub_key.split()

    for key in distro_bootstrap_keys:
        d.appendVar("SRC_URI", " %s" % key)
        fetcher = bb.fetch2.Fetch([key], d)
        filename = os.path.relpath(fetcher.localpath(key), topdir)
        d.appendVar("DISTRO_BOOTSTRAP_KEYFILES", " ${TOPDIR}/%s" % filename)

    for key in third_party_apt_keys:
        d.appendVar("SRC_URI", " %s" % key)
        fetcher = bb.fetch2.Fetch([key], d)
        filename = os.path.relpath(fetcher.localpath(key), topdir)
        d.appendVar("THIRD_PARTY_APT_KEYFILES", " ${TOPDIR}/%s" % filename)

    distro_apt_sources = get_aptsources_list(d)
    for file in distro_apt_sources:
        d.appendVar("SRC_URI", " file://%s" % file)

    distro_apt_preferences = d.getVar(d.getVar("DISTRO_VARS_PREFIX") + "DISTRO_APT_PREFERENCES") or ""
    for file in distro_apt_preferences.split():
        d.appendVar("SRC_URI", " file://%s" % file)
}

def aggregate_files(d, file_list, file_out):
    import shutil

    with open(file_out, "wb") as out_fd:
        for entry in file_list:
            entry_real = bb.parse.resolve_file(entry, d)
            with open(entry_real, "rb") as in_fd:
                 shutil.copyfileobj(in_fd, out_fd, 1024*1024*10)
            out_fd.write("\n".encode())

def parse_aptsources_list_line(source_list_line):
    import re

    s = source_list_line.strip()

    if not s or s.startswith("#"):
        return None

    type, s = re.split("\s+", s, maxsplit=1)
    if type not in ["deb", "deb-src"]:
        return None

    options = ""
    options_match = re.match("\[\s*(\S+=\S+(?=\s))*\s*(\S+=\S+)\s*\]\s+", s)
    if options_match:
        options = options_match.group(0).strip()
        s = s[options_match.end():]

    source, s = re.split("\s+", s, maxsplit=1)

    if s.startswith("/"):
        suite = ""
    else:
        suite, s = re.split("\s+", s, maxsplit=1)

    components = " ".join(s.split())

    return [type, options, source, suite, components]

def get_apt_source_mirror(d, aptsources_entry_list):
    import re

    if bb.utils.to_boolean(d.getVar('ISAR_USE_CACHED_BASE_REPO')):
        premirrors = "\S* file://${REPO_BASE_DIR}/${BOOTSTRAP_BASE_DISTRO}\n"
    else:
        premirrors = d.getVar('DISTRO_APT_PREMIRRORS') or ""
    mirror_list = [entry.split()
                  for entry in premirrors.split('\\n')
                  if any(entry)]

    for regex, replace in mirror_list:
        match = re.search(regex, aptsources_entry_list[2])

        if match:
            new_aptsources_entry_list = aptsources_entry_list.copy()
            new_aptsources_entry_list[2] = re.sub(regex, replace,
                                                  aptsources_entry_list[2],
                                                  count = 1)
            return new_aptsources_entry_list

    return aptsources_entry_list

def aggregate_aptsources_list(d, file_list, file_out):
    import shutil

    with open(file_out, "wb") as out_fd:
        for entry in file_list:
            entry_real = bb.parse.resolve_file(entry, d)
            with open(entry_real, "r") as in_fd:
                for line in in_fd:
                    parsed = parse_aptsources_list_line(line)
                    if parsed:
                        parsed = get_apt_source_mirror(d, parsed)
                        out_fd.write(" ".join(parsed).encode())
                    else:
                        out_fd.write(line.encode())
                    out_fd.write("\n".encode())
            out_fd.write("\n".encode())

def get_aptsources_list(d):
    import errno
    from collections import OrderedDict
    apt_sources_var = d.getVar("DISTRO_VARS_PREFIX") + "DISTRO_APT_SOURCES"
    apt_sources_list = list(OrderedDict.fromkeys((d.getVar(apt_sources_var) or "").split()))
    for p in apt_sources_list:
        try:
            bb.parse.resolve_file(p, d)
        except FileNotFoundError as e:
            bb.fatal(os.strerror(errno.ENOENT) + ' "' + p + '"')
    return apt_sources_list

def generate_distro_sources(d):
    apt_sources_list = get_aptsources_list(d)
    for entry in apt_sources_list:
        with open(bb.parse.resolve_file(entry, d), "r") as in_fd:
            for line in in_fd:
                parsed = parse_aptsources_list_line(line)
                if parsed:
                    parsed = get_apt_source_mirror(d, parsed)
                    yield parsed

def get_distro_primary_source_entry(d):
    for source in generate_distro_sources(d):
        if source[0] == "deb":
            return source[2:]
    bb.fatal('Invalid apt sources list')

def get_distro_suite(d):
    return get_distro_primary_source_entry(d)[1]

def get_distro_components_argument(d):
    components = get_distro_primary_source_entry(d)[2]
    if components and components.strip():
        return "--components=" + ",".join(components.split())
    else:
        return ""

DISTRO_BOOTSTRAP_KEYRING = "${WORKDIR}/distro-keyring.gpg"

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

do_apt_config_prepare[dirs] = "${WORKDIR}"
do_apt_config_prepare[vardeps] += " \
    APTPREFS \
    ${DISTRO_VARS_PREFIX}DISTRO_APT_PREFERENCES \
    DEBDISTRONAME \
    APTSRCS \
    ${DISTRO_VARS_PREFIX}DISTRO_APT_SOURCES \
    DEPLOY_ISAR_BOOTSTRAP \
    "
python do_apt_config_prepare() {
    apt_preferences_out = d.getVar("APTPREFS")
    apt_preferences_list = (
        d.getVar(d.getVar("DISTRO_VARS_PREFIX") + "DISTRO_APT_PREFERENCES") or ""
    ).split()
    aggregate_files(d, apt_preferences_list, apt_preferences_out)

    apt_sources_out = d.getVar("APTSRCS")
    apt_sources_init_out = d.getVar("APTSRCS_INIT")
    apt_sources_list = get_aptsources_list(d)

    aggregate_files(d, apt_sources_list, apt_sources_init_out)
    aggregate_aptsources_list(d, apt_sources_list, apt_sources_out)
}
addtask apt_config_prepare before do_bootstrap after do_unpack

def get_host_release():
    import platform
    rel = platform.release()
    return rel

do_bootstrap[vardeps] += " \
    DISTRO_APT_PREMIRRORS \
    ISAR_ENABLE_COMPAT_ARCH \
    ${DISTRO_VARS_PREFIX}DISTRO_APT_SOURCES \
    "
do_bootstrap[dirs] = "${DEPLOY_DIR_BOOTSTRAP} ${BOOTSTRAP_TMPDIR} ${WORKDIR}/trusted.gpg.d ${WORKDIR}/sources.list.d"
do_bootstrap[depends] = "base-apt:do_cache isar-apt:do_cache_config"
do_bootstrap[network] = "${TASK_USE_NETWORK_AND_SUDO}"

inherit compat

DEB_DL_LOCK ?= "${DEBDIR}/${BOOTSTRAP_BASE_DISTRO}-${BASE_DISTRO_CODENAME}.lock"

do_bootstrap() {
    if [ "${ISAR_ENABLE_COMPAT_ARCH}" = "1" ]; then
        if [ -z "${COMPAT_DISTRO_ARCH}" ]; then
            bbfatal "${DISTRO_ARCH} does not have a compat arch"
        fi
    fi
    bootstrap_args="--verbose --variant=minbase --include=${DISTRO_BOOTSTRAP_BASE_PACKAGES}"
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
                         mount --bind '${REPO_BASE_DIR}' \$1/$base_apt_tmp"
        # replace base-apt mount in tmp with /base-apt mount
        extra_customize="sed -i \"s|copy://$base_apt_tmp|file:///base-apt|g\" \
                             \$1/etc/apt/sources.list.d/*.list && \
                         mkdir -p \$1/base-apt && \
                         mount --bind '${REPO_BASE_DIR}' \$1/base-apt && \
                         chroot \$1 apt-get update -y \
                                -o APT::Update::Error-Mode=any && \
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
                                 -o Apt::Architecture="${BOOTSTRAP_DISTRO_ARCH}"'
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

    sudo TMPDIR="${BOOTSTRAP_TMPDIR}" mmdebstrap $bootstrap_args \
                   $arch_param \
                   --mode=unshare \
                   ${MMHOOKS} \
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
                   ${@get_distro_components_argument(d)} \
                   "${@get_distro_suite(d)}" \
                   "${WORKDIR}/rootfs.tar.zst" \
                   "$bootstrap_list"

    if [ -n "${SOURCE_DATE_EPOCH}" ]; then
        export SOURCE_DATE_EPOCH="${SOURCE_DATE_EPOCH}"
    fi

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

CLEANFUNCS = "clean_deploy"
clean_deploy() {
    rm -f "${DEPLOY_ISAR_BOOTSTRAP}"
}
