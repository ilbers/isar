# This software is a part of ISAR.
# Copyright (C) Siemens AG, 2024-2025
#
# SPDX-License-Identifier: MIT

inherit dpkg-raw
inherit target-bootstrapper

DESCRIPTION = "Device bootstrapping framework"

TARGET_BOOTSTRAPPER_ADDITIONAL_PACKAGES ??= "deploy-image"
TARGET_BOOTSTRAPPER_TASK_deploy-image[script] ??= "deploy-image-wic.sh"
TARGET_BOOTSTRAPPER_TASK_deploy-image[workdir] ??= "/usr/bin"
TARGET_BOOTSTRAPPER_TASK_deploy-image[effort] ??= "2"

DEPENDS += " ${@isar_multiarch_packages('TARGET_BOOTSTRAPPER_ADDITIONAL_PACKAGES', d)}"
DEBIAN_DEPENDS += " \
  , bash \
  , ${@ ', '.join(isar_multiarch_packages('TARGET_BOOTSTRAPPER_ADDITIONAL_PACKAGES', d).split())} \
  "

SRC_URI = " \
    file://target-bootstrapper.sh.tmpl \
    "

TEMPLATE_FILES = " \
    target-bootstrapper.sh.tmpl \
    "

TEMPLATE_VARS = " \
    TMPL_TARGET_BOOTSTRAPPER_TASK_NAMES \
    TMPL_TARGET_BOOTSTRAPPER_TASK_WORKDIRS \
    TMPL_TARGET_BOOTSTRAPPER_TASK_SCRIPTS \
    TMPL_TARGET_BOOTSTRAPPER_TASK_EFFORTS \
    TMPL_TARGET_BOOTSTRAPPER_TASK_TOTAL_EFFORT \
    "

do_install[cleandirs] = "${D}/usr/bin/"
do_install() {
    install -m 0755  ${WORKDIR}/target-bootstrapper.sh ${D}/usr/bin/
}
