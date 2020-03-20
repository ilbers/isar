# UBI image recipe
#
# This software is a part of ISAR.
# Copyright (C) Siemens AG, 2019
#
# SPDX-License-Identifier: MIT

DESCRIPTION = "UBI Isar image"

LICENSE = "gpl-2.0"
LIC_FILES_CHKSUM = "file://${LAYERDIR_core}/licenses/COPYING.GPLv2;md5=751419260aa954499f7abaabaa882bbe"

inherit image

SRC_URI += "file://ubinize.cfg.tmpl \
            file://fitimage.its.tmpl"

TEMPLATE_VARS = "KERNEL_IMG INITRD_IMG DTB_IMG UBIFS_IMG FIT_IMG"
TEMPLATE_FILES = "ubinize.cfg.tmpl fitimage.its.tmpl"

KERNEL_IMG = "${PP_DEPLOY}/${KERNEL_IMAGE}"
INITRD_IMG = "${PP_DEPLOY}/${INITRD_IMAGE}"
# only one dtb file supported, pick the first
DTB_IMG = "${PP_DEPLOY}/${@(d.getVar('DTB_FILES').split() or [''])[0]}"

UBIFS_IMG = "${PP_DEPLOY}/${UBIFS_IMAGE_FILE}"
FIT_IMG = "${PP_DEPLOY}/${FIT_IMAGE_FILE}"
