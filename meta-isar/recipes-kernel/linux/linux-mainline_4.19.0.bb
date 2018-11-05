# Example recipe for building the mainline kernel
#
# This software is a part of ISAR.
# Copyright (c) Siemens AG, 2018
#
# SPDX-License-Identifier: MIT

require recipes-kernel/linux/linux-custom.inc

ARCHIVE_VERSION = "${@d.getVar('PV').strip('.0')}"

SRC_URI += " \
    https://cdn.kernel.org/pub/linux/kernel/v4.x/linux-${ARCHIVE_VERSION}.tar.xz \
    file://x86_64_defconfig"
SRC_URI[sha256sum] = "0c68f5655528aed4f99dae71a5b259edc93239fa899e2df79c055275c21749a1"

S = "${WORKDIR}/linux-${ARCHIVE_VERSION}"

KERNEL_DEFCONFIG_qemuamd64 = "x86_64_defconfig"
