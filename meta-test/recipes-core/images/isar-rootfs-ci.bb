# CI root filesystem for target installation (without kernel, initrd, ...)
#
# This software is a part of ISAR.
# Copyright (C) 2025 Siemens

# Bill-of-material
ROOTFS_MANIFEST_DEPLOY_DIR = "${DEPLOY_DIR_IMAGE}"

ROOTFSDIR = "${WORKDIR}/rootfs"
ROOTFS_FEATURES = "generate-sbom"

inherit multiarch
inherit rootfs

# behave similar to image class, so we can reuse the testing infrastructure
DEPENDS += "${IMAGE_INSTALL}"
ROOTFS_PACKAGES += "${IMAGE_PREINSTALL} ${@isar_multiarch_packages('IMAGE_INSTALL', d)}"
