#
# Copyright (c) Siemens AG, 2023-2024
#
# SPDX-License-Identifier: MIT

inherit linux-kernel

SRC_URI += " \
    https://github.com/starfive-tech/linux/archive/${SRCREV}.tar.gz;downloadfilename=linux-starfive-${SRCREV}.tar.gz \
    file://0001-btrfs-fix-kvcalloc-arguments-order-in-btrfs_ioctl_se.patch \
    file://0001-drm-img-rogue-fix-build-issue-on-GNU-Make-4.4.patch \
    file://starfive2_extra.cfg"
SRCREV = "d0e7c0486d768a294f4f2b390d00dab8bee5d726"
SRC_URI[sha256sum] = "86f1bb78a84222d4a3d22779e335023a228cd865df866fd08af6a7816eca3add"

S = "${WORKDIR}/linux-${SRCREV}"

KERNEL_DEFCONFIG = "starfive_visionfive2_defconfig"

LINUX_VERSION_EXTENSION = "-isar"

COMPATIBLE_MACHINE = "^(starfive-visionfive2)$"
