# This software is a part of ISAR.
# Copyright (C) Siemens AG, 2019
#
# SPDX-License-Identifier: MIT
#
# This class extends the image.bbclass to supply the creation of a sdk

SDKCHROOT_DIR = "${TMPDIR}/work/${DISTRO}-${DISTRO_ARCH}/sdkchroot-${HOST_DISTRO}-${HOST_ARCH}"

do_populate_sdk[stamp-extra-info] = "${DISTRO}-${MACHINE}"
do_populate_sdk[depends] = "sdkchroot:do_build"
do_populate_sdk() {
    # Copy isar-apt with deployed Isar packages
    sudo cp -Trpfx ${REPO_ISAR_DIR}/${DISTRO}  ${SDKCHROOT_DIR}/rootfs/isar-apt

    # Purge apt cache to make image slimmer
    sudo rm -rf ${SDKCHROOT_DIR}/rootfs/var/cache/apt/*

    sudo umount -R ${SDKCHROOT_DIR}/rootfs/dev || true
    sudo umount ${SDKCHROOT_DIR}/rootfs/proc || true
    sudo umount -R ${SDKCHROOT_DIR}/rootfs/sys || true

    # Remove setup scripts
    sudo rm -f ${SDKCHROOT_DIR}/rootfs/chroot-setup.sh ${SDKCHROOT_DIR}/rootfs/configscript.sh

    # Copy mount_chroot.sh for convenience
    sudo cp ${ISARROOT}/scripts/mount_chroot.sh ${SDKCHROOT_DIR}/rootfs

    # Create SDK archive
    sudo tar -C ${SDKCHROOT_DIR} --transform="s|^rootfs|sdk-${DISTRO}-${DISTRO_ARCH}|" \
        -c rootfs | xz -T0 > ${DEPLOY_DIR_IMAGE}/sdk-${DISTRO}-${DISTRO_ARCH}.tar.xz

    # Install deployment link for local use
    ln -Tfsr ${SDKCHROOT_DIR}/rootfs ${DEPLOY_DIR_IMAGE}/sdk-${DISTRO}-${DISTRO_ARCH}
}
addtask populate_sdk after do_rootfs
