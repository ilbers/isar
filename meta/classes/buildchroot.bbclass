# This software is a part of ISAR.
# Copyright (C) 2018 Siemens AG
#
# SPDX-License-Identifier: MIT

ISAR_CROSS_COMPILE ??= "0"

# Add dependency from the correct buildchroot: host or target
python __anonymous() {
    mode = d.getVar('ISAR_CROSS_COMPILE', True)
    if mode == "0":
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
    sudo flock ${MOUNT_LOCKFILE} -c ' \
        set -e
        if ! grep -q ${BUILDCHROOT_DIR}/isar-apt /proc/mounts; then
            mount --bind ${REPO_ISAR_DIR}/${DISTRO} ${BUILDCHROOT_DIR}/isar-apt
            mount --bind ${DL_DIR} ${BUILDCHROOT_DIR}/downloads
            mount --rbind /dev ${BUILDCHROOT_DIR}/dev
            mount --make-rslave ${BUILDCHROOT_DIR}/dev
            mount -t proc none ${BUILDCHROOT_DIR}/proc
            mount --rbind /sys ${BUILDCHROOT_DIR}/sys
            mount --make-rslave ${BUILDCHROOT_DIR}/sys
        fi

        # Refresh /etc/resolv.conf at this chance
        cp -L /etc/resolv.conf ${BUILDCHROOT_DIR}/etc
        '
}
