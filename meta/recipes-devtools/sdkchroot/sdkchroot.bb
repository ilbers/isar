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

SDKCHROOT_PREINSTALL := "debhelper \
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

do_build[dirs] = "${DEPLOY_DIR_IMAGE}"
do_build[stamp-extra-info] = "${HOST_DISTRO}-${HOST_ARCH}"
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

    setup_root_file_system --copyisarapt --host-arch --host-distro "${S}" $packages

    # Configure root filesystem
    sudo install -m 755 ${WORKDIR}/configscript.sh ${S}
    sudo chroot ${S} /configscript.sh  ${DISTRO_ARCH}

    # Create SDK archive
    sudo umount ${S}/dev ${S}/proc
    sudo tar -C ${WORKDIR} --transform="s|^rootfs|sdk-${DISTRO}-${DISTRO_ARCH}|" \
        -c rootfs | xz -T0 > ${DEPLOY_DIR_IMAGE}/sdk-${DISTRO}-${DISTRO_ARCH}.tar.xz

    # Install deployment link for local use
    ln -Tfsr ${S} ${DEPLOY_DIR_IMAGE}/sdk-${DISTRO}-${DISTRO_ARCH}
}
