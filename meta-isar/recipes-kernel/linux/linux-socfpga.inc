DESCRIPTION = "Linux Kernel for Intel SoCFPGA"
LICENSE = "GPLv2"


KERNEL_REPO ?= "git://github.com/altera-opensource/linux-socfpga.git"
KERNEL_PROT ?= "https"
KBRANCH ?= "${LINUX_VERSION_PREFIX}${LINUX_VERSION}${LINUX_VERSION_SUFFIX}"


require recipes-kernel/linux/linux-custom.inc

SRC_URI += "${KERNEL_REPO};protocol=${KERNEL_PROT};branch=${KBRANCH};destsuffix=${P}"

# Kernel CONFIG_LOCALVERSION

LINUX_VERSION_EXTENSION = "-isar"


# Build branch name
LINUX_VERSION_PREFIX ?= "socfpga-"
LINUX_VERSION_SUFFIX ?= ""
LINUX_VERSION ?= "4.0"



SRCREV ?= "${AUTOREV}"
SRCREV_machine ?= "${AUTOREV}"


KERNEL_DEFCONFIG ?= "socfpga_defconfig"


