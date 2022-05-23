LINUX_VERSION = "5.10.80"
LINUX_VERSION_SUFFIX = "-lts"

LIC_FILES_CHKSUM = "file://COPYING;md5=6bc538ed5bd9a7fc9398086aedcd7e46"

SRCREV = "39e34e799228fd8568feec92612298497842a8e0"

include linux-socfpga.inc

FILESEXTRAPATHS_prepend := "${THISDIR}/config:"

SRC_URI += "file://socfpga_defconfig "

SRC_URI_append_agilex = " file://jffs2.scc file://gpio_sys.scc "


#LINUX_VERSION_EXTENSION = "-isar"

