# This software is a part of ISAR.
# Copyright (C) Siemens AG, 2019

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

    if [ -n "${OS_RELEASE_BUILD_ID}" ]; then
        sudo sed -i '/^BUILD_ID=.*/d' '${IMAGE_ROOTFS}/etc/os-release'
        echo "BUILD_ID=\"${OS_RELEASE_BUILD_ID}\"" | \
            sudo tee -a '${IMAGE_ROOTFS}/etc/os-release'
    fi
    if [ -n "${OS_RELEASE_VARIANT}" ]; then
        sudo sed -i '/^VARIANT=.*/d' '${IMAGE_ROOTFS}/etc/os-release'
        echo "VARIANT=\"${OS_RELEASE_VARIANT}\"" | \
            sudo tee -a '${IMAGE_ROOTFS}/etc/os-release'
    fi
}

ROOTFS_POSTPROCESS_COMMAND =+ "image_postprocess_configure image_postprocess_mark"

image_postprocess_configure() {
    # Configure root filesystem
    if [ -n "${DISTRO_CONFIG_SCRIPT}" ]; then
        sudo install -m 755 "${WORKDIR}/${DISTRO_CONFIG_SCRIPT}" "${IMAGE_ROOTFS}"
        TARGET_DISTRO_CONFIG_SCRIPT="$(basename ${DISTRO_CONFIG_SCRIPT})"
        sudo chroot ${IMAGE_ROOTFS} "/$TARGET_DISTRO_CONFIG_SCRIPT" \
                                    "${MACHINE_SERIAL}" "${BAUDRATE_TTY}"
        sudo rm "${IMAGE_ROOTFS}/$TARGET_DISTRO_CONFIG_SCRIPT"
   fi
}

image_postprocess_mark() {
    BUILD_ID=$(get_build_id)
    update_etc_os_release \
        --build-id "${BUILD_ID}" --variant "${DESCRIPTION}"
}
