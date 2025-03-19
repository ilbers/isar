# This software is a part of Isar.
# Copyright (c) Siemens AG, 2018-2021
# Copyright (C) 2024 ilbers GmbH
#
# SPDX-License-Identifier: MIT

FILESEXTRAPATHS:append = ":${BBPATH}"

SRC_URI = " \
    file://locale \
    file://chroot-setup.sh \
    ${DISTRO_BOOTSTRAP_KEYS} \
    ${THIRD_PARTY_APT_KEYS}"

BOOTSTRAP_FOR_HOST ?= "0"

APTPREFS = "${WORKDIR}/apt-preferences"
APTSRCS = "${WORKDIR}/apt-sources"
APTSRCS_INIT = "${WORKDIR}/apt-sources-init"
DISTRO_BOOTSTRAP_KEYFILES = ""
THIRD_PARTY_APT_KEYFILES = ""
DISTRO_BOOTSTRAP_KEYS ?= ""
THIRD_PARTY_APT_KEYS ?= ""
DEPLOY_ISAR_BOOTSTRAP ?= ""
DISTRO_BOOTSTRAP_BASE_PACKAGES ??= ""
DISTRO_VARS_PREFIX ?= "${@'HOST_' if bb.utils.to_boolean(d.getVar('BOOTSTRAP_FOR_HOST')) else ''}"
BOOTSTRAP_DISTRO = "${@d.getVar('HOST_DISTRO' if bb.utils.to_boolean(d.getVar('BOOTSTRAP_FOR_HOST')) else 'DISTRO')}"
BOOTSTRAP_BASE_DISTRO = "${@d.getVar('HOST_BASE_DISTRO' if bb.utils.to_boolean(d.getVar('BOOTSTRAP_FOR_HOST')) else 'BASE_DISTRO')}"
BOOTSTRAP_DISTRO_ARCH = "${@d.getVar('HOST_ARCH' if bb.utils.to_boolean(d.getVar('BOOTSTRAP_FOR_HOST')) else 'DISTRO_ARCH')}"
ISAR_APT_SNAPSHOT_DATE ?= "${@ get_isar_apt_snapshot_date(d)}"
ISAR_APT_SNAPSHOT_DATE[security] ?= "${@ get_isar_apt_snapshot_date(d, 'security')}"

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
        fetcher = bb.fetch2.Fetch([key], d)
        filename = os.path.relpath(fetcher.localpath(key), topdir)
        d.appendVar("DISTRO_BOOTSTRAP_KEYFILES", " ${TOPDIR}/%s" % filename)

    for key in third_party_apt_keys:
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

def get_isar_apt_snapshot_date(d, dist=None):
    import time
    source_date_epoch = d.getVar('ISAR_APT_SNAPSHOT_TIMESTAMP')
    if dist:
        source_date_epoch = d.getVarFlag('ISAR_APT_SNAPSHOT_TIMESTAMP', dist) or source_date_epoch
    return time.strftime('%Y%m%dT%H%M%SZ', time.gmtime(int(source_date_epoch)))

def get_apt_source_mirror(d, aptsources_entry_list):
    import re

    # this is executed during parsing. No error checking possible
    use_snapshot = bb.utils.to_boolean(d.getVar('ISAR_USE_APT_SNAPSHOT'))
    snapshot_mirror = d.getVar('DISTRO_APT_SNAPSHOT_PREMIRROR')
    if bb.utils.to_boolean(d.getVar('ISAR_USE_CACHED_BASE_REPO')):
        premirrors = "\S* file://${REPO_BASE_DIR}/${BOOTSTRAP_BASE_DISTRO}\n"
    elif use_snapshot and snapshot_mirror:
        premirrors = snapshot_mirror
    else:
        premirrors = d.getVar('DISTRO_APT_PREMIRRORS') or ""
    mirror_list = [entry.split()
                  for entry in premirrors.split('\\n')
                  if any(entry) and len(entry.split()) == 2]

    for regex, replace in mirror_list:
        match = re.search(regex, aptsources_entry_list[2])

        if match:
            new_aptsources_entry_list = aptsources_entry_list.copy()
            new_aptsources_entry_list[2] = re.sub(regex, replace,
                                                  aptsources_entry_list[2],
                                                  count = 1)
            if use_snapshot:
                new_aptsources_entry_list[1] = "[check-valid-until=no]"
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

def get_distro_source(d):
    return get_distro_primary_source_entry(d)[0]

def get_distro_suite(d):
    return get_distro_primary_source_entry(d)[1]

def get_distro_components_argument(d):
    components = get_distro_primary_source_entry(d)[2]
    if components and components.strip():
        return "--components=" + ",".join(components.split())
    else:
        return ""

do_apt_config_prepare[dirs] = "${WORKDIR}"
do_apt_config_prepare[vardeps] += " \
    APTPREFS \
    ${DISTRO_VARS_PREFIX}DISTRO_APT_PREFERENCES \
    DEBDISTRONAME \
    APTSRCS \
    ${DISTRO_VARS_PREFIX}DISTRO_APT_SOURCES \
    DEPLOY_ISAR_BOOTSTRAP \
    ${@'DISTRO_APT_SNAPSHOT_PREMIRROR' if bb.utils.to_boolean(d.getVar('ISAR_USE_APT_SNAPSHOT')) else ''} \
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

CLEANFUNCS = "clean_deploy"
clean_deploy() {
    rm -f "${DEPLOY_ISAR_BOOTSTRAP}"
}
