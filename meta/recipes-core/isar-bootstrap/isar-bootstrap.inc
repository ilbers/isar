# Minimal debian root file system
#
# This software is a part of ISAR.
# Copyright (c) Siemens AG, 2018
#
# SPDX-License-Identifier: MIT

LICENSE = "gpl-2.0"
LIC_FILES_CHKSUM = "file://${LAYERDIR_isar}/licenses/COPYING.GPLv2;md5=751419260aa954499f7abaabaa882bbe"
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
APTKEYFILES = ""
APTKEYRING = "${WORKDIR}/apt-keyring.gpg"
DEBOOTSTRAP_KEYRING = ""
DEPLOY_ISAR_BOOTSTRAP ?= ""

python () {
    from urllib.parse import urlparse
    distro_apt_keys = d.getVar("DISTRO_APT_KEYS", False)
    if distro_apt_keys:
        d.setVar("DEBOOTSTRAP_KEYRING", "--keyring ${APTKEYRING}")
        for key in distro_apt_keys.split():
            url = urlparse(key)
            filename = os.path.basename(url.path)
            d.appendVar("SRC_URI", " %s" % key)
            d.appendVar("APTKEYFILES", " %s" % filename)
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

    if s.startswith("#"):
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

def get_distro_primary_source_entry(d, is_host=False):
    if is_host:
        apt_sources_list = (d.getVar("HOST_DISTRO_APT_SOURCES", True) or "").split()
    else:
        apt_sources_list = (d.getVar("DISTRO_APT_SOURCES", True) or "").split()
    for entry in apt_sources_list:
        entry_real = bb.parse.resolve_file(entry, d)
        with open(entry_real, "r") as in_fd:
            for line in in_fd:
                parsed = parse_aptsources_list_line(line)
                if parsed:
                    parsed = get_apt_source_mirror(d, parsed)
                    if parsed[0] == "deb":
                        return parsed[2:]
    return ["", "", ""]

def get_distro_source(d, is_host):
    return get_distro_primary_source_entry(d, is_host)[0]

def get_distro_suite(d, is_host):
    return get_distro_primary_source_entry(d, is_host)[1]

def get_distro_components_argument(d, is_host):
    components = get_distro_primary_source_entry(d, is_host)[2]
    if components and components.strip():
        return "--components=%s" % ",".join(components.split())
    else:
        return ""

do_generate_keyring[dirs] = "${WORKDIR}"
do_generate_keyring[vardeps] += "DISTRO_APT_KEYS"
do_generate_keyring() {
    if [ -n "${@d.getVar("APTKEYFILES", True) or ""}" ]; then
        for keyfile in ${@d.getVar("APTKEYFILES", True)}; do
           gpg --no-default-keyring --keyring "${APTKEYRING}" \
               --homedir "${WORKDIR}" --import "$keyfile"
        done
    fi
}
addtask generate_keyring before do_build after do_unpack



def get_host_release():
    import platform
    rel = platform.release()
    return rel


do_bootstrap[vardeps] += "DISTRO_APT_PREMIRRORS"
do_bootstrap[dirs] = "${DEPLOY_DIR_IMAGE}"

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
    sudo flock "${ISAR_BOOTSTRAP_LOCK}" -c "\
        if [ ! -e "${DEPLOY_ISAR_BOOTSTRAP}" ]; then
            if [ -e "${ROOTFSDIR}" ]; then
               sudo umount -l "${ROOTFSDIR}/dev" || true
               sudo umount -l "${ROOTFSDIR}/proc" || true
               sudo rm -rf "${ROOTFSDIR}"
            fi
            E="${@bb.utils.export_proxies(d)}"
            if [ ${IS_HOST} ]; then
                sudo -E "${DEBOOTSTRAP}" --verbose \
                                         --variant=minbase \
                                         --include=locales \
                                         ${@get_distro_components_argument(d, True)} \
                                         ${DEBOOTSTRAP_KEYRING} \
                                         "${@get_distro_suite(d, True)}" \
                                         "${ROOTFSDIR}" \
                                         "${@get_distro_source(d, True)}"

            else
                 sudo -E "${DEBOOTSTRAP}" --verbose \
                                          --variant=minbase \
                                          --arch="${DISTRO_ARCH}" \
                                          --include=locales \
                                          ${@get_distro_components_argument(d, False)} \
                                          ${DEBOOTSTRAP_KEYRING} \
                                         "${@get_distro_suite(d, False)}" \
                                         "${ROOTFSDIR}" \
                                         "${@get_distro_source(d, False)}"
            fi

            # Install apt config
            sudo mkdir -p "${ROOTFSDIR}/etc/apt/preferences.d"
            sudo install -v -m644 "${APTPREFS}" \
                                  "${ROOTFSDIR}/etc/apt/preferences.d/bootstrap"
            sudo mkdir -p "${ROOTFSDIR}/etc/apt/sources.list.d"
            sudo install -v -m644 "${APTSRCS}" \
                                  "${ROOTFSDIR}/etc/apt/sources.list.d/bootstrap.list"
            sudo rm -f "${ROOTFSDIR}/etc/apt/sources.list"
            sudo mkdir -p "${ROOTFSDIR}/etc/apt/apt.conf.d"
            sudo install -v -m644 "${WORKDIR}/isar-apt.conf" \
                                  "${ROOTFSDIR}/etc/apt/apt.conf.d/50isar.conf"

            if [ "${@get_distro_suite(d, True)}" = "stretch" ] && [ "${@get_host_release().split('.')[0]}" -lt "4" ]; then
                sudo install -v -m644 "${WORKDIR}/isar-apt-fallback.conf" \
                                      "${ROOTFSDIR}/etc/apt/apt.conf.d/55isar-fallback.conf"
            fi

            # Set locale
            sudo install -v -m644 "${WORKDIR}/locale" "${ROOTFSDIR}/etc/locale"

            sudo sed -i '/en_US.UTF-8 UTF-8/s/^#//g' "${ROOTFSDIR}/etc/locale.gen"
            sudo -E chroot "${ROOTFSDIR}" /usr/sbin/locale-gen

            # setup chroot
            sudo install -v -m755 "${WORKDIR}/chroot-setup.sh" "${ROOTFSDIR}/chroot-setup.sh"
            sudo "${ROOTFSDIR}/chroot-setup.sh" "setup" "${ROOTFSDIR}"

            # update APT
            sudo mount -t devtmpfs -o mode=0755,nosuid devtmpfs ${ROOTFSDIR}/dev
            sudo mount -t proc none ${ROOTFSDIR}/proc

            E="${@bb.utils.export_proxies(d)}"
            export DEBIAN_FRONTEND=noninteractive
            sudo -E chroot "${ROOTFSDIR}" /usr/bin/apt-get update -y
            sudo -E chroot "${ROOTFSDIR}" /usr/bin/apt-get dist-upgrade -y \
                                      -o Debug::pkgProblemResolver=yes

            # Finalize debootstrap by setting the link in deploy
            ln -Tfsr "${ROOTFSDIR}" "${DEPLOY_ISAR_BOOTSTRAP}"
        fi"
}

CLEANFUNCS = "clean_deploy"
clean_deploy() {
    rm -f "${DEPLOY_ISAR_BOOTSTRAP}"
}
