# Root filesystem for packages building
#
# This software is a part of ISAR.
# Copyright (C) 2015-2016 ilbers GmbH

DESCRIPTION = "Multistrap development filesystem"

LICENSE = "gpl-2.0"
LIC_FILES_CHKSUM = "file://${LAYERDIR_isar}/licenses/COPYING.GPLv2;md5=751419260aa954499f7abaabaa882bbe"

FILESPATH_prepend := "${THISDIR}/files:"
SRC_URI = "file://configscript.sh \
           file://build.sh"
PV = "1.0"

inherit isar-bootstrap-helper

BUILDCHROOT_PREINSTALL ?= "gcc \
                           make \
                           build-essential \
                           debhelper \
                           autotools-dev \
                           dpkg \
                           locales \
                           docbook-to-man \
                           apt \
                           automake \
                           devscripts \
                           equivs"

WORKDIR = "${TMPDIR}/work/${DISTRO}-${DISTRO_ARCH}/${PN}"

do_build[stamp-extra-info] = "${DISTRO}-${DISTRO_ARCH}"
do_build[root_cleandirs] = "${BUILDCHROOT_DIR} \
                            ${BUILDCHROOT_DIR}/isar-apt \
                            ${BUILDCHROOT_DIR}/downloads \
                            ${BUILDCHROOT_DIR}/home/builder"
do_build[depends] = "isar-apt:do_cache_config isar-bootstrap:do_deploy"

do_build() {
    CDIRS="${@d.expand(d.getVarFlags("do_build").get("root_cleandirs", ""))}"
    if [ -n "$CDIRS" ]; then
        sudo rm -rf $CDIRS
        mkdir -p $CDIRS
    fi

    setup_root_file_system "${BUILDCHROOT_DIR}" "noclean" \
        ${BUILDCHROOT_PREINSTALL}

    # Install package builder script
    sudo chmod -R a+rw "${BUILDCHROOT_DIR}/home/builder"
    sudo install -m 755 ${WORKDIR}/build.sh ${BUILDCHROOT_DIR}

    # Configure root filesystem
    sudo install -m 755 ${WORKDIR}/configscript.sh ${BUILDCHROOT_DIR}
    sudo chroot ${BUILDCHROOT_DIR} /configscript.sh
}
