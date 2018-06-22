# Helper functions for using isar-bootstrap
#
# This software is a part of ISAR.
# Copyright (c) Siemens AG, 2018
#
# SPDX-License-Identifier: MIT

IMAGE_TRANSIENT_PACKAGES ??= ""

def get_deb_host_arch():
    import subprocess
    arch =  subprocess.check_output(['/usr/bin/dpkg-architecture', '-q', 'DEB_HOST_ARCH'], universal_newlines=True)
    return str.splitlines(arch)[0]

#Debian Distribution for SDK host
HOST_DISTRO ?= "debian-stretch"
#Determine SDK host architecture if not explicitly set
HOST_ARCH ?= "${@get_deb_host_arch()}"

HOST_DISTRO_APT_SOURCES += "conf/distro/${HOST_DISTRO}.list"

def reverse_bb_array(d, varname):
    array = d.getVar(varname, True)
    if array is None:
        return None
    array = reversed(array.split())
    return " ".join(i for i in array)


setup_root_file_system() {
    CLEAN=""
    FSTAB=""
    ROOTFS_ARCH="${DISTRO_ARCH}"
    ROOTFS_DISTRO="${DISTRO}"
    while true; do
        case "$1" in
        --clean) CLEAN=1 ;;
        --fstab) FSTAB=$2; shift ;;
        --host-arch) ROOTFS_ARCH=${HOST_ARCH} ;;
        --host-distro) ROOTFS_DISTRO=${HOST_DISTRO} ;;
        -*) bbfatal "$0: invalid option specified: $1" ;;
        *) break ;;
        esac
        shift
    done
    ROOTFSDIR="$1"
    shift
    PACKAGES="$@"
    APT_ARGS="install --yes -o Debug::pkgProblemResolver=yes"
    CLEAN_FILES="${ROOTFSDIR}/etc/hostname ${ROOTFSDIR}/etc/resolv.conf"

    sudo cp -Trpfx \
        "${DEPLOY_DIR_IMAGE}/isar-bootstrap-$ROOTFS_DISTRO-$ROOTFS_ARCH/" \
        "$ROOTFSDIR"
    [ -n "${FSTAB}" ] && cat ${FSTAB} | sudo tee "$ROOTFSDIR/etc/fstab"

    echo "deb [trusted=yes] file:///isar-apt ${DEBDISTRONAME} main" | \
        sudo tee "$ROOTFSDIR/etc/apt/sources.list.d/isar-apt.list" >/dev/null

    echo "Package: *\nPin: release n=${DEBDISTRONAME}\nPin-Priority: 1000" | \
        sudo tee "$ROOTFSDIR/etc/apt/preferences.d/isar" >/dev/null

    sudo mount --bind ${DEPLOY_DIR_APT}/${ROOTFS_DISTRO} $ROOTFSDIR/isar-apt

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
        /usr/bin/apt-get ${APT_ARGS} --download-only $PACKAGES \
            ${IMAGE_TRANSIENT_PACKAGES}
    [ ${CLEAN} ] && sudo rm -f ${CLEAN_FILES}
    sudo -E chroot "$ROOTFSDIR" \
        /usr/bin/apt-get ${APT_ARGS} $PACKAGES
    for pkg in ${IMAGE_TRANSIENT_PACKAGES}; do
        sudo -E chroot "$ROOTFSDIR" \
            /usr/bin/apt-get ${APT_ARGS} $pkg
    done
    for pkg in ${@reverse_bb_array(d, "IMAGE_TRANSIENT_PACKAGES") or ""}; do
        sudo -E chroot "$ROOTFSDIR" \
            /usr/bin/apt-get purge --yes $pkg
    done
    if [ ${CLEAN} ]; then
        sudo -E chroot "$ROOTFSDIR" \
            /usr/bin/apt-get autoremove --purge --yes
        sudo -E chroot "$ROOTFSDIR" \
            /usr/bin/apt-get clean
        sudo "$ROOTFSDIR/chroot-setup.sh" "cleanup" "$ROOTFSDIR"
        sudo rm -f "$ROOTFSDIR/chroot-setup.sh"
    fi
}
