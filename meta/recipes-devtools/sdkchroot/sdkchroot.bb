# SDK Root filesystem
#
# This software is a part of ISAR.
# Copyright (C) 2015-2018 ilbers GmbH

DESCRIPTION = "Isar SDK Root filesystem"

LICENSE = "gpl-2.0"
LIC_FILES_CHKSUM = "file://${LAYERDIR_isar}/licenses/COPYING.GPLv2;md5=751419260aa954499f7abaabaa882bbe"

SRC_URI = "file://configscript.sh"
PV = "0.1"

inherit isar-bootstrap-helper

SDKCHROOT_PREINSTALL := "crossbuild-essential-${DISTRO_ARCH} \
                           debhelper \
                           autotools-dev \
                           dpkg \
                           locales \
                           docbook-to-man \
                           apt \
                           automake \
                           devscripts \
                           equivs"

WORKDIR = "${TMPDIR}/work/${DISTRO}-${DISTRO_ARCH}/${PN}-${HOST_DISTRO}-${HOST_ARCH}"
S = "${WORKDIR}/rootfs"

do_build[stamp-extra-info] = "${HOST_DISTRO}-${HOST_ARCH}"
do_build[root_cleandirs] = "${S} \
                            ${S}/isar-apt"

do_build[depends] = "isar-apt-host:do_cache_config isar-bootstrap-host:do_bootstrap"

do_build() {

    if [ ${HOST_DISTRO} != "debian-stretch" ]; then
         bbfatal "SDK doesn't support ${HOST_DISTRO}"
    fi

    setup_root_file_system --copyisarapt --host-arch --host-distro "${S}" ${SDKCHROOT_PREINSTALL}

    # Configure root filesystem
    sudo install -m 755 ${WORKDIR}/configscript.sh ${S}
    sudo chroot ${S} /configscript.sh  ${DISTRO_ARCH}
}
