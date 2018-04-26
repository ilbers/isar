# Helper functions for using isar-bootstrap
#
# This software is a part of ISAR.
# Copyright (c) Siemens AG, 2018
#
# SPDX-License-Identifier: MIT

setup_root_file_system() {
    ROOTFSDIR="$1"
    CLEANHOSTLEAK="$2"
    shift
    shift
    PACKAGES="$@"
    APT_ARGS="install --yes --allow-unauthenticated \
              -o Debug::pkgProblemResolver=yes"
    CLEANHOSTLEAK_FILES="${ROOTFSDIR}/etc/hostname ${ROOTFSDIR}/etc/resolv.conf"

    sudo cp -Trpfx \
        "${DEPLOY_DIR_IMAGE}/isar-bootstrap-${DISTRO}-${DISTRO_ARCH}/" \
        "$ROOTFSDIR"

    echo "deb file:///isar-apt ${DEBDISTRONAME} main" | \
        sudo tee "$ROOTFSDIR/etc/apt/sources.list.d/isar-apt.list" >/dev/null

    echo "Package: *\nPin: release n=${DEBDISTRONAME}\nPin-Priority: 1000" | \
        sudo tee "$ROOTFSDIR/etc/apt/preferences.d/isar" >/dev/null

    sudo mount --bind ${DEPLOY_DIR_APT}/${DISTRO} $ROOTFSDIR/isar-apt
    sudo mount -t devtmpfs -o mode=0755,nosuid devtmpfs $ROOTFSDIR/dev
    sudo mount -t proc none $ROOTFSDIR/proc

    # Install packages:
    E="${@ bb.utils.export_proxies(d)}"
    export DEBIAN_FRONTEND=noninteractive
    # To avoid Perl locale warnings:
    export LANG=C
    export LANGUAGE=C
    export LC_ALL=C
    sudo -E chroot "$ROOTFSDIR" /usr/bin/apt-get update \
        -o Dir::Etc::sourcelist="sources.list.d/isar-apt.list" \
        -o Dir::Etc::sourceparts="-" \
        -o APT::Get::List-Cleanup="0"
    sudo -E chroot "$ROOTFSDIR" \
        /usr/bin/apt-get ${APT_ARGS} --download-only $PACKAGES
    [ "clean" = ${CLEANHOSTLEAK} ] && sudo rm -f ${CLEANHOSTLEAK_FILES}
    sudo -E chroot "$ROOTFSDIR" \
        /usr/bin/apt-get ${APT_ARGS} $PACKAGES
}
