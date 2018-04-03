# Minimal debian root file system
#
# This software is a part of ISAR.
# Copyright (c) Siemens AG, 2018
#
# SPDX-License-Identifier: MIT

Description = "Minimal debian root file system"

LICENSE = "gpl-2.0"
LIC_FILES_CHKSUM = "file://${LAYERDIR_isar}/licenses/COPYING.GPLv2;md5=751419260aa954499f7abaabaa882bbe"
FILESPATH_prepend := "${THISDIR}/files:"
SRC_URI = "file://isar-apt.conf"
PV = "1.0"

WORKDIR = "${TMPDIR}/work/${DISTRO}-${DISTRO_ARCH}/${PN}"
DEBOOTSTRAP ?= ""
ROOTFSDIR = "${WORKDIR}/rootfs"
APTPREFS = "${WORKDIR}/apt-preferences"
APTSRCS = "${WORKDIR}/apt-sources"
APTKEYFILES = ""
APTKEYRING = "${WORKDIR}/apt-keyring.gpg"
DEBOOTSTRAP_KEYRING = ""

python () {
    from urllib.parse import urlparse

    debootstrap = d.getVar("DEBOOTSTRAP", True)
    if not debootstrap:
        target = d.getVar("DISTRO_ARCH", True)
        machine = os.uname()[4]
        m = {
            "x86_64": ["i386", "amd64"],
            "x86": ["i386"],
            }
        if machine not in m or target not in m[machine]:
            debootstrap = "qemu-debootstrap"
        else:
            debootstrap = "debootstrap"
        d.setVar("DEBOOTSTRAP", debootstrap)

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

    return type, options, source, suite, components

def get_distro_primary_source_entry(d):
    apt_sources_list = (d.getVar("DISTRO_APT_SOURCES", True) or "").split()
    for entry in apt_sources_list:
        entry_real = bb.parse.resolve_file(entry, d)
        with open(entry_real, "r") as in_fd:
            for line in in_fd:
                parsed = parse_aptsources_list_line(line)
                if parsed:
                    type, _, source, suite, components = parsed
                    if type == "deb":
                        return source, suite, components
    return "", "", ""

def get_distro_source(d):
    return get_distro_primary_source_entry(d)[0]

def get_distro_suite(d):
    return get_distro_primary_source_entry(d)[1]

def get_distro_components_argument(d):
    components = get_distro_primary_source_entry(d)[2]
    if components and components.strip():
        return "--components=%s" % ",".join(components.split())
    else:
        return ""

do_generate_keyring[stamp-extra-info] = "${DISTRO}-${DISTRO_ARCH}"
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

do_apt_config_prepare[stamp-extra-info] = "${DISTRO}-${DISTRO_ARCH}"
do_apt_config_prepare[vardeps] += "\
                                   APTPREFS \
                                   DISTRO_APT_PREFERENCES \
                                   DEBDISTRONAME \
                                   APTSRCS \
                                   DISTRO_APT_SOURCES \
                                  "
python do_apt_config_prepare() {
    apt_preferences_out = d.getVar("APTPREFS", True)
    apt_preferences_list = (d.getVar("DISTRO_APT_PREFERENCES", True) or ""
                           ).split()
    aggregate_files(d, apt_preferences_list, apt_preferences_out)

    apt_sources_out = d.getVar("APTSRCS", True)
    apt_sources_list = (d.getVar("DISTRO_APT_SOURCES", True) or "").split()

    aggregate_files(d, apt_sources_list, apt_sources_out)
}
addtask apt_config_prepare before do_build after do_generate_keyring

do_bootstrap[stamp-extra-info] = "${DISTRO}-${DISTRO_ARCH}"
do_bootstrap[vardeps] += "DISTRO_APT_SOURCES"
do_bootstrap() {
    if [ -e "${ROOTFSDIR}" ]; then
       sudo umount -l "${ROOTFSDIR}/dev" || true
       sudo umount -l "${ROOTFSDIR}/proc" || true
       sudo rm -rf "${ROOTFSDIR}"
    fi
    E="${@bb.utils.export_proxies(d)}"
    sudo -E "${DEBOOTSTRAP}" --verbose \
                             --variant minbase \
                             --arch "${DISTRO_ARCH}" \
                             ${@get_distro_components_argument(d)} \
                             ${DEBOOTSTRAP_KEYRING} \
                             "${@get_distro_suite(d)}" \
                             "${ROOTFSDIR}" \
                             "${@get_distro_source(d)}"
}
addtask bootstrap before do_build after do_apt_config_prepare

do_apt_config_install[stamp-extra-info] = "${DISTRO}-${DISTRO_ARCH}"
do_apt_config_install() {
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
}
addtask apt_config_install before do_build after do_bootstrap

do_apt_update[stamp-extra-info] = "${DISTRO}-${DISTRO_ARCH}"
do_apt_update() {
    sudo mount -t devtmpfs -o mode=0755,nosuid devtmpfs ${ROOTFSDIR}/dev
    sudo mount -t proc none ${ROOTFSDIR}/proc

    E="${@bb.utils.export_proxies(d)}"
    export DEBIAN_FRONTEND=noninteractive
    sudo -E chroot "${ROOTFSDIR}" /usr/bin/apt-get update -y
    sudo -E chroot "${ROOTFSDIR}" /usr/bin/apt-get dist-upgrade -y \
                                      -o Debug::pkgProblemResolver=yes
}
addtask apt_update before do_build after do_apt_config_install

do_deploy[stamp-extra-info] = "${DISTRO}-${DISTRO_ARCH}"
do_deploy[dirs] = "${DEPLOY_DIR_IMAGE}"
do_deploy() {
    ln -Tfsr "${ROOTFSDIR}" "${DEPLOY_DIR_IMAGE}/${PN}-${DISTRO}-${DISTRO_ARCH}"
}
addtask deploy before do_build after do_apt_update

CLEANFUNCS = "clean_deploy"
clean_deploy() {
     rm -f "${DEPLOY_DIR_IMAGE}/${PN}-${DISTRO}-${DISTRO_ARCH}"
}
