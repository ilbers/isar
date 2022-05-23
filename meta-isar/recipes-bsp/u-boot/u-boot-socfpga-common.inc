HOMEPAGE = "http://www.denx.de/wiki/U-Boot/WebHome"
SECTION = "bootloaders"


#DEPENDS += "coreutils-native bc-native bison-native dtc-native flex-native"
#DEPENDS += "python3-setuptools-native swig-native"
#DEPENDS += "python3-setuptools-native swig-native u-boot-mkimage-native"
#DEPENDS += "u-boot-tools virtual/kernel"

require recipes-bsp/u-boot/u-boot.inc

LICENSE = "GPLv2+"
LIC_FILES_CHKSUM ?= "file://Licenses/README;md5=30503fd321432fc713238f582193b78e"
PE = "1"

UBOOT_REPO ?= "git://github.com/altera-opensource/u-boot-socfpga.git"
UBOOT_PROT ?= "https"

UBOOT_VERSION_PREFIX ?= "socfpga_"
UBOOT_VERSION ?= "v2020.07"
UBOOT_BRANCH ?= "${UBOOT_VERSION_PREFIX}${UBOOT_VERSION}"

SRCREV ?= "${AUTOREV}"
#PV:append = "+git${SRCPV}"

#S = "${WORKDIR}/git"
#B = "${WORKDIR}/build"

RPROVIDES:${PN} += "u-boot"

SRC_URI += "${UBOOT_REPO};protocol=${UBOOT_PROT};branch=${UBOOT_BRANCH};destsuffix=${P}"
SRC_URI += "file://0001-u-boot-patch-manual-steps-2021.07.patch"
#SRC_URI += "file://file.tar.gz"
#SRC_URI += "file://0001-u-boot-socfpga-v2021.07-with-manual-steps.patch"
#SRC_URI += "${ATF_REPO};protocol=${ATF_PROT};branch=${ATF_BRANCH};destsuffix=${P}"

UBOOT_CONFIG_agilex-socdk = "socfpga_agilex_legacy_defconfig"


#UBOOT_CONFIG[de0-nano-soc] = "socfpga_de0_nano_soc_defconfig"
#UBOOT_CONFIG[de10-nano-soc] = "socfpga_de10_nano_defconfig"


#require ${COREBASE}/meta/recipes-bsp/u-boot/u-boot.inc
