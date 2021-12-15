# This software is a part of ISAR.
# Copyright (C) Siemens AG, 2021
#
# SPDX-License-Identifier: MIT
#
# This class extends the image.bbclass for containerizing the root filesystem.

CONTAINER_IMAGE_FORMATS ?= "docker-archive"
CONTAINER_IMAGE_NAME ?= "${PN}-${DISTRO}-${DISTRO_ARCH}"
CONTAINER_IMAGE_TAG ?= "${PV}-${PR}"

containerize_rootfs() {
    local cmd="/bin/dash"
    local empty_tag="empty"
    local tag="${CONTAINER_IMAGE_TAG}"
    local oci_img_dir="${WORKDIR}/oci-image"
    local rootfs="$1"
    local container_formats="$2"
    local container_name_prefix="$3"

    # prepare OCI container image skeleton
    bbdebug 1 "prepare OCI container image skeleton"
    sudo rm -rf "${oci_img_dir}" "${oci_img_dir}_unpacked"
    sudo umoci init --layout "${oci_img_dir}"
    sudo umoci new --image "${oci_img_dir}:${empty_tag}"
    sudo umoci config --image "${oci_img_dir}:${empty_tag}" \
        --config.cmd="${cmd}"
    sudo umoci unpack --image "${oci_img_dir}:${empty_tag}" \
        "${oci_img_dir}_unpacked"

    # add root filesystem as the flesh of the skeleton
    sudo cp -a "${rootfs}"/* "${oci_img_dir}_unpacked/rootfs/"
    # clean-up temporary files
    sudo find "${oci_img_dir}_unpacked/rootfs/tmp" -mindepth 1 -delete

    # pack container image
    bbdebug 1 "pack container image"
    sudo umoci repack --image "${oci_img_dir}:${tag}" \
        "${oci_img_dir}_unpacked"
    sudo umoci remove --image "${oci_img_dir}:${empty_tag}"
    sudo rm -rf "${oci_img_dir}_unpacked"

    # no root needed anymore
    sudo chown --recursive $(id -u):$(id -g) "${oci_img_dir}"

    # convert the OCI container image to the desired format
    image_name="${container_name_prefix}${CONTAINER_IMAGE_NAME}"
    for image_type in ${CONTAINER_IMAGE_FORMATS} ; do
        image_archive="${DEPLOY_DIR_IMAGE}/${image_name}-${tag}-${image_type}.tar"
        bbdebug 1 "Creating container image type: ${image_type}"
        case "${image_type}" in
            "docker-archive" | "oci-archive")
                if [ "${image_type}" = "oci-archive" ] ; then
                    target="${image_type}:${image_archive}:${tag}"
                else
                    target="${image_type}:${image_archive}:${image_name}:${tag}"
                fi
                rm -f "${image_archive}" "${image_archive}.xz"
                bbdebug 2 "Converting OCI image to ${image_type}"
                skopeo --insecure-policy copy \
                    "oci:${oci_img_dir}:${tag}" "${target}"
                bbdebug 2 "Compressing image"
                xz -T0 "${image_archive}"
                ;;
            "oci")
                tar --create --xz --directory "${oci_img_dir}" \
                    --file "${image_archive}.xz" .
                ;;
            "docker-daemon" | "containers-storage")
                if [ -f /.dockerenv ] || [ -f /run/.containerenv ] ; then
                    die "Adding the container image to a container runtime (${image_type}) not supported if running from a container (e.g. 'kas-container')"
                fi
                skopeo --insecure-policy copy \
                    "oci:${oci_img_dir}:${tag}" \
                    "${image_type}:${image_name}:${tag}"
                ;;
            *)
                die "Unsupported format for containerize_rootfs: ${image_type}"
                ;;
        esac
    done
}

