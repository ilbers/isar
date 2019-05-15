# Helper functions for using isar-bootstrap
#
# This software is a part of ISAR.
# Copyright (c) Siemens AG, 2018
#
# SPDX-License-Identifier: MIT

IMAGE_TRANSIENT_PACKAGES ??= ""

HOST_DISTRO_APT_SOURCES += "conf/distro/${HOST_DISTRO}.list"

def reverse_bb_array(d, varname):
    array = d.getVar(varname, True)
    if array is None:
        return None
    array = reversed(array.split())
    return " ".join(i for i in array)


update_etc_os_release() {
    OS_RELEASE_BUILD_ID=""
    OS_RELEASE_VARIANT=""
    while true; do
        case "$1" in
	--build-id) OS_RELEASE_BUILD_ID=$2; shift ;;
	--variant) OS_RELEASE_VARIANT=$2; shift ;;
        -*) bbfatal "$0: invalid option specified: $1" ;;
        *) break ;;
        esac
        shift
    done
    ROOTFSDIR="$1"

    if [ -n "${OS_RELEASE_BUILD_ID}" ]; then
        sudo sed -i '/^BUILD_ID=.*/d' ${ROOTFSDIR}/etc/os-release
        echo "BUILD_ID=\"${OS_RELEASE_BUILD_ID}\"" | \
            sudo tee -a ${ROOTFSDIR}/etc/os-release
    fi
    if [ -n "${OS_RELEASE_VARIANT}" ]; then
        sudo sed -i '/^VARIANT=.*/d' ${ROOTFSDIR}/etc/os-release
        echo "VARIANT=\"${OS_RELEASE_VARIANT}\"" | \
            sudo tee -a ${ROOTFSDIR}/etc/os-release
    fi
}

setup_root_file_system() {
    CLEAN=""
    COPYISARAPT=""
    FSTAB=""
    ROOTFS_ARCH="${DISTRO_ARCH}"
    ROOTFS_DISTRO="${DISTRO}"
    while true; do
        case "$1" in
        --clean) CLEAN=1 ;;
        --copyisarapt) COPYISARAPT=1 ;;
        --fstab) FSTAB=$2; shift ;;
        --host-arch) ROOTFS_ARCH=${HOST_ARCH} ;;
        --host-distro) ROOTFS_DISTRO=${HOST_DISTRO} ;;
        --keep-apt-cache) KEEP_APT_CACHE=1 ;;
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
        "${DEPLOY_DIR_BOOTSTRAP}/$ROOTFS_DISTRO-$ROOTFS_ARCH/" \
        "$ROOTFSDIR"
    [ -n "${FSTAB}" ] && cat ${FSTAB} | sudo tee "$ROOTFSDIR/etc/fstab"

    echo "deb [trusted=yes] file:///isar-apt ${DEBDISTRONAME} main" | \
        sudo tee "$ROOTFSDIR/etc/apt/sources.list.d/isar-apt.list" >/dev/null

    echo "Package: *\nPin: release n=${DEBDISTRONAME}\nPin-Priority: 1000" | \
        sudo tee "$ROOTFSDIR/etc/apt/preferences.d/isar" >/dev/null

    if [ ${COPYISARAPT} ]; then
        sudo cp -Trpfx ${REPO_ISAR_DIR}/${DISTRO} $ROOTFSDIR/isar-apt
    else
        sudo mount --bind ${REPO_ISAR_DIR}/${DISTRO} $ROOTFSDIR/isar-apt
    fi

    if [ "${ISAR_USE_CACHED_BASE_REPO}" = "1" ]; then
        sudo mount --bind ${REPO_BASE_DIR} ${ROOTFSDIR}/base-apt
    fi

    sudo mount --rbind /dev ${ROOTFSDIR}/dev
    sudo mount --make-rslave ${ROOTFSDIR}/dev
    sudo mount -t proc none $ROOTFSDIR/proc
    sudo mount --rbind /sys ${ROOTFSDIR}/sys
    sudo mount --make-rslave ${ROOTFSDIR}/sys

    # Refresh /etc/resolv.conf
    sudo cp -L /etc/resolv.conf ${ROOTFSDIR}/etc

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
    # Add multiarch for cross-target
    if [ "${ROOTFS_ARCH}" != "${DISTRO_ARCH}" ]; then
        sudo -E chroot "$ROOTFSDIR" /usr/bin/dpkg --add-architecture ${DISTRO_ARCH}
        sudo -E chroot "$ROOTFSDIR" /usr/bin/apt-get update
    fi
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
        if [ ${KEEP_APT_CACHE} -eq 1 ]; then
            mkdir -p ${WORKDIR}/apt_cache
            sudo find ${ROOTFSDIR}/var/cache/apt/archives \
                -maxdepth 1 -name '*.deb' -execdir /bin/mv -t ${WORKDIR}/apt_cache '{}' '+'
            sudo chown -R $(whoami) ${WORKDIR}/apt_cache
        fi
        sudo -E chroot "$ROOTFSDIR" \
            /usr/bin/apt-get autoremove --purge --yes
        sudo -E chroot "$ROOTFSDIR" \
            /usr/bin/apt-get clean
        sudo "$ROOTFSDIR/chroot-setup.sh" "cleanup" "$ROOTFSDIR"
        sudo rm -rf "$ROOTFSDIR/chroot-setup.sh" "$ROOTFSDIR/var/lib/apt/lists/"*
    fi
}
