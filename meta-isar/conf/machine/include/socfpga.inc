SOC_FAMILY = "socfpga"

require conf/machine/include/arm/armv7a/tune-cortexa9.inc

# this variable specifies the kernel to be built: linux-socfpga or linux-socfpga-ltsi
# this affects the PREFERRED_PROVIDER of virtual/kernel
# it can be overriden from the environment, using BB_ENV_EXTRAWHITE
KERNEL_PROVIDER ?= "linux-socfpga"
PREFERRED_PROVIDER_virtual/kernel ?= "${KERNEL_PROVIDER}"

PREFERRED_PROVIDER_virtual/bootloader ?= "u-boot-socfpga"
PREFERRED_PROVIDER_u-boot ?= "u-boot-socfpga"

# Increase this everytime you change something in the kernel
MACHINE_KERNEL_PR = "r1"

UBOOT_ENTRYPOINT = "0x80008000"
UBOOT_LOADADDRESS = "0x80008000"

KERNEL_IMAGETYPE ?= "zImage"
MACHINE_EXTRA_RRECOMMENDS = " kernel-modules"
MACHINE_FEATURES = "kernel26"

KBUILD_DEFCONFIG ?= "socfpga_defconfig"

# file system images required
IMAGE_FSTYPES ?= "cpio ext3 tar.gz jffs2"

# u-boot setup
UBOOT_SUFFIX ?= "sfp"
UBOOT_BINARY ?= "u-boot-with-spl.${UBOOT_SUFFIX}"

# Settings for ubifs
MKUBIFS_ARGS = "--leb-size 126976 --min-io-size 2048 --max-leb-cnt 3600"
UBINIZE_ARGS = "--peb-size 128KiB --min-io-size 2048 --sub-page-size 2048"

do_image_wic[depends] += "mtools-native:do_populate_sysroot dosfstools-native:do_populate_sysroot virtual/bootloader:do_deploy virtual/kernel:do_deploy"
