# This software is a part of ISAR.
# Copyright (C) 2018 Siemens AG
#
# SPDX-License-Identifier: MIT

ISAR_CROSS_COMPILE ??= "0"

# Add dependency from the correct buildchroot: host or target
python __anonymous() {
    mode = d.getVar('ISAR_CROSS_COMPILE', True)
    distro_arch = d.getVar('DISTRO_ARCH')
    if mode == "0" or d.getVar('HOST_ARCH') ==  distro_arch or \
       (d.getVar('HOST_DISTRO') == "debian-stretch" and distro_arch == "i386"):
        dep = "buildchroot-target:do_build"
        rootfs = d.getVar('BUILDCHROOT_TARGET_DIR', True)
    else:
        dep = "buildchroot-host:do_build"
        rootfs = d.getVar('BUILDCHROOT_HOST_DIR', True)

    d.setVarFlag('do_apt_fetch', 'depends', dep)
    d.setVar('BUILDCHROOT_DIR', rootfs)
}

MOUNT_LOCKFILE = "${BUILDCHROOT_DIR}.lock"

buildchroot_do_mounts() {
    sudo -s <<'EOSUDO'
        ( flock 9
        set -e

        count="1"
        if [ -f '${BUILDCHROOT_DIR}.mount' ]; then
            count=$(($(cat '${BUILDCHROOT_DIR}.mount') + 1))
        fi
        echo $count > '${BUILDCHROOT_DIR}.mount'
        if [ $count -gt 1 ]; then
            exit 0
        fi

        mkdir -p '${BUILDCHROOT_DIR}/isar-apt'
        mountpoint -q '${BUILDCHROOT_DIR}/isar-apt' ||
            mount --bind '${REPO_ISAR_DIR}/${DISTRO}' '${BUILDCHROOT_DIR}/isar-apt'
        mkdir -p '${BUILDCHROOT_DIR}/downloads'
        mountpoint -q '${BUILDCHROOT_DIR}/downloads' ||
            mount --bind '${DL_DIR}' '${BUILDCHROOT_DIR}/downloads'
        mountpoint -q '${BUILDCHROOT_DIR}/dev' ||
            mount --rbind /dev '${BUILDCHROOT_DIR}/dev'
        mount --make-rslave '${BUILDCHROOT_DIR}/dev'
        mountpoint -q '${BUILDCHROOT_DIR}/proc' ||
            mount -t proc none '${BUILDCHROOT_DIR}/proc'
        mountpoint -q '${BUILDCHROOT_DIR}/sys' ||
            mount --rbind /sys '${BUILDCHROOT_DIR}/sys'
        mount --make-rslave '${BUILDCHROOT_DIR}/sys'

        # Mount base-apt if 'ISAR_USE_CACHED_BASE_REPO' is set
        if [ "${@repr(bb.utils.to_boolean(d.getVar('ISAR_USE_CACHED_BASE_REPO')))}" = 'True' ]
        then
            mkdir -p '${BUILDCHROOT_DIR}/base-apt'
            mountpoint -q '${BUILDCHROOT_DIR}/base-apt' || \
                mount --bind '${REPO_BASE_DIR}' '${BUILDCHROOT_DIR}/base-apt'
        fi

        # Refresh or remove /etc/resolv.conf at this chance
        if [ "${@repr(bb.utils.to_boolean(d.getVar('BB_NO_NETWORK')))}" = 'True' ]
        then
            rm -rf '${BUILDCHROOT_DIR}/etc/resolv.conf'
        else
            cp -L /etc/resolv.conf '${BUILDCHROOT_DIR}/etc'
        fi

        ) 9>'${MOUNT_LOCKFILE}'
EOSUDO
}

buildchroot_undo_mounts() {
    sudo -s <<'EOSUDO'
        ( flock 9
        set -e

        if [ -f '${BUILDCHROOT_DIR}.mount' ]; then
            count=$(($(cat '${BUILDCHROOT_DIR}.mount') - 1))
            echo $count > '${BUILDCHROOT_DIR}.mount'
        else
            echo "Could not find mount counter"
            exit 1
        fi
        if [ $count -gt 0 ]; then
            exit 0
        fi
        rm ${BUILDCHROOT_DIR}.mount

        mountpoint -q '${BUILDCHROOT_DIR}/base-apt' && \
            umount ${BUILDCHROOT_DIR}/base-apt && \
            rmdir --ignore-fail-on-non-empty ${BUILDCHROOT_DIR}/base-apt
        mountpoint -q '${BUILDCHROOT_DIR}/sys' && \
            umount -R ${BUILDCHROOT_DIR}/sys
        mountpoint -q '${BUILDCHROOT_DIR}/proc' && \
            umount -R ${BUILDCHROOT_DIR}/proc
        mountpoint -q '${BUILDCHROOT_DIR}/dev' && \
            umount -R ${BUILDCHROOT_DIR}/dev
        mountpoint -q '${BUILDCHROOT_DIR}/downloads' && \
            umount ${BUILDCHROOT_DIR}/downloads && \
            rmdir --ignore-fail-on-non-empty ${BUILDCHROOT_DIR}/downloads
        mountpoint -q '${BUILDCHROOT_DIR}/isar-apt' && \
            umount ${BUILDCHROOT_DIR}/isar-apt && \
            rmdir --ignore-fail-on-non-empty ${BUILDCHROOT_DIR}/isar-apt
        ) 9>'${MOUNT_LOCKFILE}'
EOSUDO
}
