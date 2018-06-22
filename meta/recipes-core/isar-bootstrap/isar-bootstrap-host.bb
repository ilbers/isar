# Minimal host Debian root file system
#
# This software is a part of ISAR.
# Copyright (c) Siemens AG, 2018
#
# SPDX-License-Identifier: MIT

Description = "Minimal host Debian root file system"

WORKDIR = "${TMPDIR}/work/${DISTRO}-${DISTRO_ARCH}/${PN}-${HOST_DISTRO}-${HOST_ARCH}"

include isar-bootstrap.inc
inherit isar-bootstrap-helper

do_generate_keyring[stamp-extra-info] = "${HOST_DISTRO}-${HOST_ARCH}"

do_apt_config_prepare[stamp-extra-info] = "${HOST_DISTRO}-${HOST_ARCH}"
do_apt_config_prepare[dirs] = "${WORKDIR}"
do_apt_config_prepare[vardeps] += "\
                                   APTPREFS \
                                   HOST_DISTRO_APT_PREFERENCES \
                                   DEBDISTRONAME \
                                   APTSRCS \
                                   HOST_DISTRO_APT_SOURCES \
                                  "
python do_apt_config_prepare() {
    apt_preferences_out = d.getVar("APTPREFS", True)
    apt_preferences_list = (d.getVar("HOST_DISTRO_APT_PREFERENCES", True) or ""
                           ).split()
    aggregate_files(d, apt_preferences_list, apt_preferences_out)

    apt_sources_out = d.getVar("APTSRCS", True)
    apt_sources_list = (d.getVar("HOST_DISTRO_APT_SOURCES", True) or "").split()

    aggregate_aptsources_list(d, apt_sources_list, apt_sources_out)
}
addtask apt_config_prepare before do_build after do_unpack

do_apt_config_install[stamp-extra-info] = "${HOST_DISTRO}-${HOST_ARCH}"


do_bootstrap[stamp-extra-info] = "${HOST_DISTRO}-${HOST_ARCH}"
do_bootstrap[vardeps] += "HOST_DISTRO_APT_SOURCES"
do_bootstrap[vardeps] += "DISTRO_APT_PREMIRRORS"
do_bootstrap() {
    if [ -e "${ROOTFSDIR}" ]; then
       sudo umount -l "${ROOTFSDIR}/dev" || true
       sudo umount -l "${ROOTFSDIR}/proc" || true
       sudo rm -rf "${ROOTFSDIR}"
    fi
    E="${@bb.utils.export_proxies(d)}"
    sudo -E "${DEBOOTSTRAP}" --verbose \
                             --variant=minbase \
                             --include=locales \
                             ${@get_distro_components_argument(d, True)} \
                             ${DEBOOTSTRAP_KEYRING} \
                             "${@get_distro_suite(d, True)}" \
                             "${ROOTFSDIR}" \
                             "${@get_distro_source(d, True)}"
}
addtask bootstrap before do_build after do_generate_keyring

do_deploy[stamp-extra-info] = "${HOST_DISTRO}-${HOST_ARCH}"
do_deploy[dirs] = "${DEPLOY_DIR_IMAGE}"
do_deploy() {
    ln -Tfsr "${ROOTFSDIR}" "${DEPLOY_DIR_IMAGE}/isar-bootstrap-${HOST_DISTRO}-${HOST_ARCH}"
}
addtask deploy before do_build after do_apt_update

do_apt_update[stamp-extra-info] = "${HOST_DISTRO}-${HOST_ARCH}"

CLEANFUNCS = "clean_deploy"
clean_deploy() {
     rm -f "${DEPLOY_DIR_IMAGE}/isar-bootstrap}-${HOST_DISTRO}-${HOST_ARCH}"
}
