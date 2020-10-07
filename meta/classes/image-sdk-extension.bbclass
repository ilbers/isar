# This software is a part of ISAR.
# Copyright (C) Siemens AG, 2019
#
# SPDX-License-Identifier: MIT
#
# This class extends the image.bbclass to supply the creation of a sdk

do_populate_sdk[stamp-extra-info] = "${DISTRO}-${MACHINE}"
do_populate_sdk[depends] = "sdkchroot:do_build"
do_populate_sdk() {
    # Copy isar-apt with deployed Isar packages
    sudo cp -Trpfx ${REPO_ISAR_DIR}/${DISTRO}  ${SDKCHROOT_DIR}/isar-apt

    sudo umount -R ${SDKCHROOT_DIR}/dev || true
    sudo umount ${SDKCHROOT_DIR}/proc || true
    sudo umount -R ${SDKCHROOT_DIR}/sys || true

    # Remove setup scripts
    sudo rm -f ${SDKCHROOT_DIR}/chroot-setup.sh ${SDKCHROOT_DIR}/configscript.sh

    # Make all links relative
    for link in $(find ${SDKCHROOT_DIR}/ -type l); do
        target=$(readlink $link)

        if [ "${target#/}" != "${target}" ]; then
            basedir=$(dirname $link)
            new_target=$(realpath --no-symlinks -m --relative-to=$basedir ${SDKCHROOT_DIR}/${target})

            # remove first to allow rewriting directory links
            sudo rm $link
            sudo ln -s $new_target $link
        fi
    done

    # Copy mount_chroot.sh for convenience
    sudo cp ${SCRIPTSDIR}/mount_chroot.sh ${SDKCHROOT_DIR}

    # Create SDK archive
    cd -P ${SDKCHROOT_DIR}/..
    sudo tar --transform="s|^rootfs|sdk-${DISTRO}-${DISTRO_ARCH}|" \
        -c rootfs | xz -T0 > ${DEPLOY_DIR_IMAGE}/sdk-${DISTRO}-${DISTRO_ARCH}.tar.xz
}
addtask populate_sdk after do_rootfs
