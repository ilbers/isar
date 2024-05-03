# This software is a part of ISAR.
# Copyright (C) Siemens AG, 2021
#
# SPDX-License-Identifier: MIT
#
# This class provides the task 'containerize'
# to create container images containing the target rootfs.

CONTAINER_TYPES = "oci oci-archive docker-archive docker-daemon containers-storage"
USING_CONTAINER = "${@bb.utils.contains_any('IMAGE_BASETYPES', d.getVar('CONTAINER_TYPES').split(), '1', '0', d)}"

CONTAINER_IMAGE_NAME ?= "${PN}-${DISTRO}-${DISTRO_ARCH}"
CONTAINER_IMAGE_TAG ?= "${PV}-${PR}"

python() {
    if not bb.utils.to_boolean(d.getVar('USING_CONTAINER')):
        return
    for t in d.getVar('CONTAINER_TYPES').split():
        t_clean = t.replace('-', '_').replace('.', '_')
        d.setVar('IMAGE_CMD:' + t_clean, 'convert_container %s "${CONTAINER_IMAGE_NAME}" "${IMAGE_FILE_HOST}"' % t)
        d.setVar('IMAGE_FULLNAME:' + t_clean, '${PN}-${DISTRO}-${DISTRO_ARCH}')
        d.setVarFlag('do_containerize', 'network', d.getVar('TASK_USE_SUDO'))
        bb.build.addtask('containerize', 'do_image_' + t_clean, 'do_image_tools', d)
}

do_containerize() {
    local cmd="/bin/dash"
    local empty_tag="empty"
    local tag="${CONTAINER_IMAGE_TAG}"
    local oci_img_dir="${WORKDIR}/oci-image"
    local rootfs="${IMAGE_ROOTFS}"

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
    sudo cp --reflink=auto -a "${rootfs}"/* "${oci_img_dir}_unpacked/rootfs/"
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
}

convert_container() {
    local tag="${CONTAINER_IMAGE_TAG}"
    local oci_img_dir="${WORKDIR}/oci-image"
    local container_type="$1"
    local image_name="$2"
    local image_archive="$3"

    # convert the OCI container image to the desired format
    bbdebug 1 "Creating container image type: ${container_type}"
    case "${container_type}" in
        "docker-archive" | "oci-archive")
            if [ "${container_type}" = "oci-archive" ] ; then
                target="${container_type}:${image_archive}:${tag}"
            else
                target="${container_type}:${image_archive}:${image_name}:${tag}"
            fi
            rm -f "${image_archive}"
            bbdebug 2 "Converting OCI image to ${container_type}"
            skopeo --insecure-policy copy \
                --tmpdir "${WORKDIR}" \
                "oci:${oci_img_dir}:${tag}" "${target}"
            ;;
        "oci")
            tar --create --directory "${oci_img_dir}" \
                --file "${image_archive}" .
            ;;
        "docker-daemon" | "containers-storage")
            if [ -f /.dockerenv ] || [ -f /run/.containerenv ] ; then
                die "Adding the container image to a container runtime (${container_type}) not supported if running from a container (e.g. 'kas-container')"
            fi
            skopeo --insecure-policy copy \
                --tmpdir "${WORKDIR}" \
                "oci:${oci_img_dir}:${tag}" \
                "${container_type}:${image_name}:${tag}"
            ;;
        *)
            die "Unsupported format for convert_container: ${container_type}"
            ;;
    esac
}
