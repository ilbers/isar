# This software is a part of ISAR.
# Copyright (C) 2024 ilbers GmbH

require recipes-kernel/linux/linux-custom.inc

SRC_URI += "https://git.phytec.de/linux-mainline/snapshot/linux-mainline-${PV}.tar.bz2"

SRC_URI[sha256sum] = "dcbcd5e89fd74d24b542cf311f6dc3e7b5062088f698b4ac72129d5cf310e600"

S = "${WORKDIR}/linux-mainline-${PV}"

KBUILD_DEPENDS:append = "lzop"

KERNEL_DEFCONFIG = "imx_v6_v7_defconfig"

LINUX_VERSION_EXTENSION = "-isar"

COMPATIBLE_MACHINE = "phyboard-mira"
