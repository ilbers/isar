# Minimal debian root file system
#
# This software is a part of ISAR.
# Copyright (c) Siemens AG, 2018
#
# SPDX-License-Identifier: MIT

LICENSE = "gpl-2.0"
LIC_FILES_CHKSUM = "file://${LAYERDIR_core}/licenses/COPYING.GPLv2;md5=751419260aa954499f7abaabaa882bbe"
FILESPATH_prepend := "${THISDIR}/files:"
SRC_URI = " \
    file://isar-apt.conf \
    file://isar-apt-fallback.conf \
    file://locale \
    file://chroot-setup.sh"
PV = "1.0"

DEBOOTSTRAP ?= "qemu-debootstrap"
ROOTFSDIR = "${WORKDIR}/rootfs"
APTPREFS = "${WORKDIR}/apt-preferences"
APTSRCS = "${WORKDIR}/apt-sources"
APTSRCS_INIT = "${WORKDIR}/apt-sources-init"
DISTRO_BOOTSTRAP_KEYFILES = ""
THIRD_PARTY_APT_KEYFILES = ""
DEPLOY_ISAR_BOOTSTRAP ?= ""
DISTRO_BOOTSTRAP_BASE_PACKAGES = "locales"
DISTRO_BOOTSTRAP_BASE_PACKAGES_append_gnupg = ",gnupg"
DISTRO_BOOTSTRAP_BASE_PACKAGES_append_https-support = "${@https_support(d)}"

inherit deb-dl-dir

python () {
    distro_bootstrap_keys = (d.getVar("DISTRO_BOOTSTRAP_KEYS") or "").split()

    third_party_apt_keys = (d.getVar("THIRD_PARTY_APT_KEYS") or "").split()

    # The cached repo key can be both for bootstrapping and apt package
    # installation afterwards. However, debootstrap will include the key into
    # the rootfs automatically thus the right place is distro_bootstrap_keys.

    if bb.utils.to_boolean(d.getVar('ISAR_USE_CACHED_BASE_REPO')):
        own_pub_key = d.getVar("BASE_REPO_KEY")
        if own_pub_key:
            distro_bootstrap_keys += own_pub_key.split()

    for key in distro_bootstrap_keys:
        d.appendVar("SRC_URI", " %s" % key)
        fetcher = bb.fetch2.Fetch([key], d)
        filename = fetcher.localpath(key)
        d.appendVar("DISTRO_BOOTSTRAP_KEYFILES", " %s" % filename)

    for key in third_party_apt_keys:
        d.appendVar("SRC_URI", " %s" % key)
        fetcher = bb.fetch2.Fetch([key], d)
        filename = fetcher.localpath(key)
        d.appendVar("THIRD_PARTY_APT_KEYFILES", " %s" % filename)
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

    suite, s = re.split("\s+", s, maxsplit=1)

    components = " ".join(s.split())

    return [type, options, source, suite, components]

def get_apt_source_mirror(d, aptsources_entry_list):
    import re

    if bb.utils.to_boolean(d.getVar('ISAR_USE_CACHED_BASE_REPO')):
        premirrors = "\S* file://${REPO_BASE_DIR}/${BASE_DISTRO}\n"
    else:
        premirrors = d.getVar('DISTRO_APT_PREMIRRORS', True) or ""
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

def get_aptsources_list(d, is_host=False):
    if is_host:
        apt_sources_list = (d.getVar("HOST_DISTRO_APT_SOURCES", True) or "").split()
    else:
        apt_sources_list = (d.getVar("DISTRO_APT_SOURCES", True) or "").split()
    return apt_sources_list

def generate_distro_sources(d, is_host=False):
    apt_sources_list = get_aptsources_list(d, is_host)
    for entry in apt_sources_list:
        entry_real = bb.parse.resolve_file(entry, d)
        with open(entry_real, "r") as in_fd:
            for line in in_fd:
                parsed = parse_aptsources_list_line(line)
                if parsed:
                    parsed = get_apt_source_mirror(d, parsed)
                    yield parsed

def get_distro_primary_source_entry(d, is_host=False):
    apt_sources_list = get_aptsources_list(d, is_host)
    for source in generate_distro_sources(d, is_host):
        if source[0] == "deb":
            return source[2:]
    return ["", "", ""]

def get_distro_have_https_source(d, is_host=False):
    return any(source[2].startswith("https://") for source in generate_distro_sources(d, is_host))

def https_support(d, is_host=False):
    if get_distro_suite(d, is_host) == "stretch":
        return ",apt-transport-https,ca-certificates"
    else:
        return ",ca-certificates"

def get_distro_needs_https_support(d, is_host=False):
    if get_distro_have_https_source(d, is_host):
        return "https-support"
    else:
        return ""

def get_distro_needs_gpg_support(d):
    apt_keys = d.getVar("DISTRO_BOOTSTRAP_KEYS") or ""
    apt_keys += " " + (d.getVar("THIRD_PARTY_APT_KEYS") or "")
    apt_keys += " " + (d.getVar("BASE_REPO_KEY") or "")
    if apt_keys != " ":
        return "gnupg"
    return ""

OVERRIDES_append = ":${@get_distro_needs_gpg_support(d)}"

def get_distro_source(d, is_host):
    return get_distro_primary_source_entry(d, is_host)[0]

def get_distro_suite(d, is_host):
    return get_distro_primary_source_entry(d, is_host)[1]

def get_distro_components_argument(d, is_host):
    components = get_distro_primary_source_entry(d, is_host)[2]
    if components and components.strip():
        return "--components=" + ",".join(components.split())
    else:
        return ""

APT_KEYS_DIR = "${WORKDIR}/aptkeys"
DISTRO_BOOTSTRAP_KEYRING = "${WORKDIR}/distro-keyring.gpg"

do_generate_keyrings[cleandirs] = "${APT_KEYS_DIR}"
do_generate_keyrings[dirs] = "${DL_DIR}"
do_generate_keyrings[vardeps] += "DISTRO_BOOTSTRAP_KEYS THIRD_PARTY_APT_KEYS"
do_generate_keyrings() {
    if [ -n "${@d.getVar("THIRD_PARTY_APT_KEYFILES", True) or ""}" ]; then
        chmod 777 "${APT_KEYS_DIR}"
        for keyfile in ${@d.getVar("THIRD_PARTY_APT_KEYFILES", True)}; do
           cp "$keyfile" "${APT_KEYS_DIR}"/"$(basename "$keyfile")"
        done
    fi
    if [ -n "${@d.getVar("DISTRO_BOOTSTRAP_KEYFILES", True) or ""}" ]; then
        for keyfile in ${@d.getVar("DISTRO_BOOTSTRAP_KEYFILES", True)}; do
           sudo apt-key --keyring "${DISTRO_BOOTSTRAP_KEYRING}" add $keyfile
           cp "$keyfile" "${APT_KEYS_DIR}"/"$(basename "$keyfile")"
        done
    fi
}
addtask generate_keyrings before do_build after do_unpack

def get_host_release():
    import platform
    rel = platform.release()
    return rel

do_bootstrap[vardeps] += "DISTRO_APT_PREMIRRORS ISAR_ENABLE_COMPAT_ARCH"
do_bootstrap[dirs] = "${DEPLOY_DIR_BOOTSTRAP}"
do_bootstrap[depends] = "base-apt:do_cache"

isar_bootstrap() {
    IS_HOST=""
    while true; do
        case "$1" in
        --host) IS_HOST=1 ;;
        -*) bbfatal "$0: invalid option specified: $1" ;;
        *) break ;;
        esac
        shift
    done
    if [ "${ISAR_ENABLE_COMPAT_ARCH}" = "1" ]; then
        if [ -z "${COMPAT_DISTRO_ARCH}" ]; then
            bbfatal "${DISTRO_ARCH} does not have a compat arch"
        fi
        if [ "${@get_distro_suite(d, True)}-${COMPAT_DISTRO_ARCH}" = "stretch-i386" ]; then
            bbfatal "compat arch build for stretch-i386 not supported"
        fi
    fi
    debootstrap_args="--verbose --variant=minbase --include=${DISTRO_BOOTSTRAP_BASE_PACKAGES}"
    if [ -f "${DISTRO_BOOTSTRAP_KEYRING}" ]; then
        debootstrap_args="$debootstrap_args --keyring=${DISTRO_BOOTSTRAP_KEYRING}"
    fi
    if [ "${ISAR_USE_CACHED_BASE_REPO}" = "1" -a -z "${BASE_REPO_KEY}" ]; then
        debootstrap_args="$debootstrap_args --no-check-gpg"
    fi
    E="${@ isar_export_proxies(d)}"
    export IS_HOST debootstrap_args E
    if [ ! -e "${DEPLOY_ISAR_BOOTSTRAP}" ]; then
        sudo rm -rf --one-file-system "${ROOTFSDIR}"
        deb_dl_dir_import "${ROOTFSDIR}"

        sudo -E -s <<'EOSUDO'
            set -e
            if [ ${IS_HOST} ]; then
                ${DEBOOTSTRAP} $debootstrap_args \
                               ${@get_distro_components_argument(d, True)} \
                               "${@get_distro_suite(d, True)}" \
                               "${ROOTFSDIR}" \
                               "${@get_distro_source(d, True)}"

            else
                 "${DEBOOTSTRAP}" $debootstrap_args \
                                  --arch="${DISTRO_ARCH}" \
                                  ${@get_distro_components_argument(d, False)} \
                                  "${@get_distro_suite(d, False)}" \
                                  "${ROOTFSDIR}" \
                                  "${@get_distro_source(d, False)}"
            fi

            # Install apt config
            mkdir -p "${ROOTFSDIR}/etc/apt/preferences.d"
            install -v -m644 "${APTPREFS}" \
                             "${ROOTFSDIR}/etc/apt/preferences.d/bootstrap"
            mkdir -p "${ROOTFSDIR}/etc/apt/sources.list.d"
            if [ "${ISAR_USE_CACHED_BASE_REPO}" = "1" ]; then
                line="file:///base-apt/${BASE_DISTRO} ${BASE_DISTRO_CODENAME} main"
                if [ -z "${BASE_REPO_KEY}" ]; then
                    line="[trusted=yes] ${line}"
                fi
                echo "deb ${line}" >  "${ROOTFSDIR}/etc/apt/sources.list.d/base-apt.list"
                echo "deb-src ${line}" >>  "${ROOTFSDIR}/etc/apt/sources.list.d/base-apt.list"

                mkdir -p ${ROOTFSDIR}/base-apt
                mount --bind ${REPO_BASE_DIR} ${ROOTFSDIR}/base-apt
            else
                install -v -m644 "${APTSRCS}" \
                                 "${ROOTFSDIR}/etc/apt/sources.list.d/bootstrap.list"
            fi
            install -v -m644 "${APTSRCS_INIT}" \
                                 "${ROOTFSDIR}/etc/apt/sources-list"
            rm -f "${ROOTFSDIR}/etc/apt/sources.list"
            rm -rf "${ROOTFSDIR}/var/lib/apt/lists/"*
            mkdir -p "${ROOTFSDIR}/etc/apt/apt.conf.d"
            install -v -m644 "${WORKDIR}/isar-apt.conf" \
                             "${ROOTFSDIR}/etc/apt/apt.conf.d/50isar.conf"
            find ${APT_KEYS_DIR}/ -type f | while read keyfile
            do
                kfn="$(basename $keyfile)"
                cp $keyfile "${ROOTFSDIR}/tmp/$kfn"
                chroot "${ROOTFSDIR}" /usr/bin/apt-key \
                   --keyring ${THIRD_PARTY_APT_KEYRING} add "/tmp/$kfn"
                rm "${ROOTFSDIR}/tmp/$kfn"
            done

            if [ "${@get_distro_suite(d, True)}" = "stretch" ] && [ "${@get_host_release().split('.')[0]}" -lt "4" ]; then
                install -v -m644 "${WORKDIR}/isar-apt-fallback.conf" \
                                 "${ROOTFSDIR}/etc/apt/apt.conf.d/55isar-fallback.conf"
            fi

            # Set locale
            install -v -m644 "${WORKDIR}/locale" "${ROOTFSDIR}/etc/locale"

            sed -i '/en_US.UTF-8 UTF-8/s/^#//g' "${ROOTFSDIR}/etc/locale.gen"
            chroot "${ROOTFSDIR}" /usr/sbin/locale-gen

            # setup chroot
            install -v -m755 "${WORKDIR}/chroot-setup.sh" "${ROOTFSDIR}/chroot-setup.sh"
            "${ROOTFSDIR}/chroot-setup.sh" "setup" "${ROOTFSDIR}"

            # update APT
            mount --rbind /dev ${ROOTFSDIR}/dev
            mount --make-rslave ${ROOTFSDIR}/dev
            mount -t proc none ${ROOTFSDIR}/proc
            mount --rbind /sys ${ROOTFSDIR}/sys
            mount --make-rslave ${ROOTFSDIR}/sys

            export DEBIAN_FRONTEND=noninteractive

            if [ ${IS_HOST} ]; then
                chroot "${ROOTFSDIR}" /usr/bin/dpkg --add-architecture ${DISTRO_ARCH}
            fi

            if [ "${ISAR_ENABLE_COMPAT_ARCH}" = "1" ]; then
                chroot "${ROOTFSDIR}" /usr/bin/dpkg --add-architecture ${COMPAT_DISTRO_ARCH}
            fi

            chroot "${ROOTFSDIR}" /usr/bin/apt-get update -y
            chroot "${ROOTFSDIR}" /usr/bin/apt-get install -y -f
            chroot "${ROOTFSDIR}" /usr/bin/apt-get dist-upgrade -y \
                                  -o Debug::pkgProblemResolver=yes

            umount -l "${ROOTFSDIR}/dev"
            umount -l "${ROOTFSDIR}/proc"
            umount -l "${ROOTFSDIR}/sys"
            umount -l "${ROOTFSDIR}/base-apt" || true

            # Finalize debootstrap by setting the link in deploy
            ln -Tfsr "${ROOTFSDIR}" "${DEPLOY_ISAR_BOOTSTRAP}"
EOSUDO
    fi
    deb_dl_dir_export "${ROOTFSDIR}"
}

CLEANFUNCS = "clean_deploy"
clean_deploy() {
    rm -f "${DEPLOY_ISAR_BOOTSTRAP}"
}
