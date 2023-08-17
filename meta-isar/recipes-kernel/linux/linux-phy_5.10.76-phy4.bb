require recipes-kernel/linux/linux-custom.inc

SRC_URI += "https://git.phytec.de/linux-mainline/snapshot/linux-mainline-${PV}.tar.bz2 \
            file://0001-dtbsinstall-fix-installing-DT-overlays.patch"

SRC_URI[sha256sum] = "ce0cff708da9f3dca1f6f8d6c433589fd5a5ea8db9e33114f44497ecf873f875"

S = "${WORKDIR}/linux-mainline-${PV}"

KBUILD_DEPENDS:append = "lzop"

KERNEL_DEFCONFIG = "imx_v6_v7_defconfig"

LINUX_VERSION_EXTENSION = "-isar"

COMPATIBLE_MACHINE = "phyboard-mira"
