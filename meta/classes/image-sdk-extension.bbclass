# This software is a part of ISAR.
# Copyright (C) Siemens AG, 2019
#
# SPDX-License-Identifier: MIT
#
# This class extends the image.bbclass to supply the creation of a sdk

SDK_INCLUDE_ISAR_APT ?= "0"
SDK_FORMATS ?= "tar-xz"

sdk_tar_xz() {
    # Copy mount_chroot.sh for convenience
    sudo cp ${SCRIPTSDIR}/mount_chroot.sh ${SDKCHROOT_DIR}

    # Create SDK archive
    cd -P ${SDKCHROOT_DIR}/..
    sudo tar --transform="s|^rootfs|sdk-${DISTRO}-${DISTRO_ARCH}|" \
        -c rootfs | xz -T0 > ${DEPLOY_DIR_IMAGE}/sdk-${DISTRO}-${DISTRO_ARCH}.tar.xz
    bbdebug 1 "SDK rootfs available in ${DEPLOY_DIR_IMAGE}/sdk-${DISTRO}-${DISTRO_ARCH}.tar.xz"
}

do_populate_sdk[stamp-extra-info] = "${DISTRO}-${MACHINE}"
do_populate_sdk[depends] = "sdkchroot:do_build"
do_populate_sdk[vardeps] += "SDK_INCLUDE_ISAR_APT SDK_FORMATS"
do_populate_sdk() {
    local sdk_container_formats=""

    if [ "${SDK_INCLUDE_ISAR_APT}" = "1" ]; then
        # Copy isar-apt with deployed Isar packages
        sudo cp -Trpfx ${REPO_ISAR_DIR}/${DISTRO} ${SDKCHROOT_DIR}/isar-apt
    else
        # Remove isar-apt repo entry
        sudo rm -f ${SDKCHROOT_DIR}/etc/apt/sources.list.d/isar-apt.list
    fi

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

    # Set up sysroot wrapper
    for tool_pattern in "gcc-[0-9]*" "g++-[0-9]*" "cpp-[0-9]*" "ld.bfd" "ld.gold"; do
        for tool in $(find ${SDKCHROOT_DIR}/usr/bin -type f -name "*-linux-gnu*-${tool_pattern}"); do
            sudo mv "${tool}" "${tool}.bin"
            sudo ln -sf gcc-sysroot-wrapper.sh ${tool}
        done
    done

    # separate SDK formats: TAR and container formats
    for sdk_format in ${SDK_FORMATS} ; do
        case ${sdk_format} in
            "tar-xz")
                sdk_tar_xz
                ;;
            "docker-archive" | "oci" | "oci-archive" | "docker-daemon" | "containers-storage")
                sdk_container_formats="${sdk_container_formats} ${sdk_format}"
                ;;
            *)
                die "unsupported SDK format specified: ${sdk_format}"
                ;;
        esac
    done

    # generate the SDK in all the desired container formats
    if [ -n "${sdk_container_formats}" ] ; then
        bbnote "Generating SDK container in ${sdk_container_formats} format"
        containerize_rootfs "${SDKCHROOT_DIR}" "sdk-${DISTRO}-${DISTRO_ARCH}" "${sdk_container_formats}"
    fi
}

addtask populate_sdk after do_rootfs
