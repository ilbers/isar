# This software is a part of Isar.
#
# Copyright (C) 2026 Siemens

LICENSE = "gpl-2.0"
LIC_FILES_CHKSUM = "file://${LAYERDIR_core}/licenses/COPYING.GPLv2;md5=751419260aa954499f7abaabaa882bbe"

HOST_TOOLING_PACKAGES ?= "dracut-core binutils zstd dracut-cross-ldd"
HOST_TOOLING_DEPENDS ?= "dracut-cross-ldd"

# dependency to build the host-tooling-chroot
HOST_TOOLING_DEP ?= "host-tooling-chroot:do_build"
HOST_TOOLING_DEPLOY_DIR ?= "${DEPLOY_DIR}/chroot-host-tooling"
HOST_TOOLING_CHROOT ?= "${HOST_TOOLING_DEPLOY_DIR}/${HOST_DISTRO}-${HOST_ARCH}_${DISTRO}-${DISTRO_ARCH}.tar.zst"
