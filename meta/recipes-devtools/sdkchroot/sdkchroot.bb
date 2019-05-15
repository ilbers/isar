# SDK Root filesystem
#
# This software is a part of ISAR.
# Copyright (C) 2015-2018 ilbers GmbH

DESCRIPTION = "Isar SDK Root filesystem"

LICENSE = "gpl-2.0"
LIC_FILES_CHKSUM = "file://${LAYERDIR_core}/licenses/COPYING.GPLv2;md5=751419260aa954499f7abaabaa882bbe"

SRC_URI = " \
    file://configscript.sh \
    file://README.sdk"
PV = "0.1"

inherit isar-bootstrap-helper
PF = "${PN}-${HOST_DISTRO}-${HOST_ARCH}-${DISTRO_ARCH}"

SDKCHROOT_PREINSTALL := "debhelper \
                           autotools-dev \
                           dpkg \
                           locales \
                           docbook-to-man \
                           apt \
                           automake \
                           devscripts \
                           equivs"

S = "${WORKDIR}/rootfs"

do_build[dirs] = "${DEPLOY_DIR_IMAGE}"
do_build[root_cleandirs] = "${S} \
                            ${S}/isar-apt"

do_build[depends] = "isar-apt:do_cache_config isar-bootstrap-host:do_bootstrap"

do_build() {

    if [ ${HOST_DISTRO} != "debian-stretch" ]; then
        bbfatal "SDK doesn't support ${HOST_DISTRO}"
    fi
    if [ ${HOST_ARCH} != "i386" -a ${HOST_ARCH} != "amd64" ]; then
        bbfatal "SDK doesn't support ${HOST_ARCH} as host"
    fi

    if [ ${HOST_ARCH} = ${DISTRO_ARCH} -o ${DISTRO_ARCH} = "i386" ]; then
        packages="${SDKCHROOT_PREINSTALL} build-essential"
    else
        packages="${SDKCHROOT_PREINSTALL} crossbuild-essential-${DISTRO_ARCH}"
    fi

    setup_root_file_system --copyisarapt --host-arch '${HOST_ARCH}' --host-distro '${HOST_DISTRO}' "${S}" $packages

    # Configure root filesystem
    sudo install -m 644 ${WORKDIR}/README.sdk ${S}
    sudo install -m 755 ${WORKDIR}/configscript.sh ${S}
    sudo chroot ${S} /configscript.sh  ${DISTRO_ARCH}
}
