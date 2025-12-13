# Copy the target image to the installer image
#
# This software is a part of ISAR.
# Copyright (C) Siemens AG, 2024
#
# SPDX-License-Identifier: MIT

inherit rootfs-add-files

INSTALLER_MC ??= "isar-installer"
INSTALLER_TARGET_IMAGE ??= "isar-image-base"
INSTALLER_TARGET_IMAGES ??= "${INSTALLER_TARGET_IMAGE}"
INSTALLER_TARGET_MC ??= "installer-target"
INSTALLER_TARGET_DISTRO ??= "${DISTRO}"
INSTALLER_TARGET_MACHINE ??= "${MACHINE}"
INSTALLER_TARGET_DEPLOY_DIR_IMAGE ??= "${DEPLOY_DIR}/images/${INSTALLER_TARGET_MACHINE}"

IMAGE_DATA_FILE ??= "${INSTALLER_TARGET_IMAGE}-${INSTALLER_TARGET_DISTRO}-${INSTALLER_TARGET_MACHINE}"
IMAGE_DATA_POSTFIX ??= "wic.zst"
IMAGE_DATA_POSTFIX:buster ??= "wic.xz"
IMAGE_DATA_POSTFIX:bullseye ??= "wic.xz"

def get_installer_sources(d, suffix):
    installer_target_images = sorted(set((d.getVar('INSTALLER_TARGET_IMAGES') or "").split()))
    if not installer_target_images:
        return [""]
    target_deploy_dir = d.getVar('INSTALLER_TARGET_DEPLOY_DIR_IMAGE')
    target_distro = d.getVar('INSTALLER_TARGET_DISTRO')
    target_machine = d.getVar('INSTALLER_TARGET_MACHINE')
    sources = []
    for image in installer_target_images:
        image_data = f"{image}-{target_distro}-{target_machine}"
        sources.append(f"{target_deploy_dir}/{image_data}.{suffix}")
    return sources

def get_installer_destinations(d, suffix):
    installer_target_images = sorted(set((d.getVar('INSTALLER_TARGET_IMAGES') or "").split()))
    if not installer_target_images:
        return ["/install/keep"]
    target_distro = d.getVar('INSTALLER_TARGET_DISTRO')
    target_machine = d.getVar('INSTALLER_TARGET_MACHINE')
    dests = []
    for image in installer_target_images:
        image_data = f"{image}-{target_distro}-{target_machine}"
        dests.append(f"/install/{image_data}.{suffix}")
    return dests

def get_mc_depends(d, task):
    installer_target_images = sorted(set((d.getVar('INSTALLER_TARGET_IMAGES') or "").split()))
    if not installer_target_images:
        return ""
    installer_mc = d.getVar('INSTALLER_MC') or ""
    installer_target_mc = d.getVar('INSTALLER_TARGET_MC') or ""
    deps = []
    for image in installer_target_images:
        deps.append(f"mc:{installer_mc}:{installer_target_mc}:{image}:{task}")
    return " ".join(deps)

def get_image_type(suffix):
    image_type = suffix.split(".")[0]
    return f"{image_type}"

python() {
    entries = []

    def add_entries(postfix, suffix):
        sources = get_installer_sources(d, suffix)
        dests = get_installer_destinations(d, suffix)

        for idx, (src, dst) in enumerate(zip(sources, dests)):
            name = f"installer-target-{idx}{postfix}"
            var = f"ROOTFS_ADDITIONAL_FILE_{name}"
            entries.append(name)
            d.setVarFlag(var, "source", src)
            d.setVarFlag(var, "destination", dst)

    add_entries("", d.getVar("IMAGE_DATA_POSTFIX"))
    add_entries("-bmap", "wic.bmap")

    d.setVar("ROOTFS_ADDITIONAL_FILES", " ".join(entries))
}

INSTALLER_TARGET_TASK ??="do_image_${@ get_image_type(d.getVar('IMAGE_DATA_POSTFIX'))}"
do_rootfs_install[mcdepends] += "${@ get_mc_depends(d, d.getVar('INSTALLER_TARGET_TASK'))}"
