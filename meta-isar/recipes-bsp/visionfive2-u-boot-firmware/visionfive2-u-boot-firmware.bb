#
# Copyright (c) Siemens AG, 2023
#
# SPDX-License-Identifier: MIT

inherit dpkg

DESCRIPTION = "StarFive VisionFive 2 u-boot firmware"

IMAGE_ITS_FILE = "visionfive2-uboot-fit-image.its"
SRC_URI = " \
    file://${IMAGE_ITS_FILE}.tmpl \
    file://rules.tmpl \
    file://visionfive2-u-boot-firmware.install"

DEPENDS += "opensbi-starfive-visionfive2 linux-image-${KERNEL_NAME}"
DEBIAN_BUILD_DEPENDS += "opensbi-starfive-visionfive2, u-boot-tools, device-tree-compiler, linux-image-${KERNEL_NAME}"

TEMPLATE_FILES = "${IMAGE_ITS_FILE}.tmpl rules.tmpl"
TEMPLATE_VARS = "IMAGE_ITS_FILE DTB_FILES"

do_prepare_build[cleandirs] += "${S}/debian"
do_prepare_build(){
    cp ${WORKDIR}/${IMAGE_ITS_FILE} ${S}/
    cp ${WORKDIR}/visionfive2-u-boot-firmware.install ${S}/debian/
    deb_debianize
}

do_deploy() {
    dpkg --fsys-tarfile ${WORKDIR}/visionfive2-u-boot-firmware_${PV}*.deb | \
        tar xOf - "./usr/share/visionfive2-u-boot-firmware/visionfive2_fw_payload.img" \
        > "${DEPLOY_DIR_IMAGE}/visionfive2_fw_payload.img"
}

addtask deploy after do_dpkg_build before do_build
do_deploy[dirs] = "${DEPLOY_DIR_IMAGE}"
