# This software is a part of ISAR.
# Copyright (C) 2018 Siemens AG
#
# SPDX-License-Identifier: MIT

ISAR_CROSS_COMPILE ??= "0"

# Add dependency from the correct buildchroot: host or target
python __anonymous() {
    mode = d.getVar('ISAR_CROSS_COMPILE', True)
    if mode == "0" or d.getVar('HOST_ARCH') == d.getVar('DISTRO_ARCH'):
        dep = "buildchroot-target:do_build"
        rootfs = d.getVar('BUILDCHROOT_TARGET_DIR', True)
    else:
        dep = "buildchroot-host:do_build"
        rootfs = d.getVar('BUILDCHROOT_HOST_DIR', True)

    d.setVarFlag('do_prepare_build', 'depends', dep)
    d.setVar('BUILDCHROOT_DIR', rootfs)
}

MOUNT_LOCKFILE = "${BUILDCHROOT_DIR}/mount.lock"

buildchroot_do_mounts() {
    sudo -s <<'EOSUDO'
        ( flock 9
        set -e
        mountpoint -q '${BUILDCHROOT_DIR}/isar-apt' ||
            mount --bind '${REPO_ISAR_DIR}/${DISTRO}' '${BUILDCHROOT_DIR}/isar-apt'
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

        # Refresh /etc/resolv.conf at this chance
        cp -L /etc/resolv.conf '${BUILDCHROOT_DIR}/etc'
        ) 9>'${MOUNT_LOCKFILE}'
EOSUDO
}
