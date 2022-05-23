require arm-trusted-firmware.inc

ATF_PROT ?= "https"
ATF_BRANCH ?= "socfpga_v2.3"
ATF_REPO ?= "git://github.com/altera-opensource/arm-trusted-firmware.git"

SRC_URI += "${ATF_REPO};protocol=${ATF_PROT};branch=${ATF_BRANCH}"

S = "${WORKDIR}/arm-trusted-firmware-${PV}"
DEBIAN_BUILD_DEPENDS += ", device-tree-compiler"

TF_A_PLATFORM = "agilex"

TF_A_EXTRA_BUILDARGS = " \
bl31 \
DEPRECATED=1 \
HANDLE_EA_EL3_FIRST=1 "
TF_A_BINARIES = " "

LIC_FILES_CHKSUM = "file://docs/license.rst;md5=713afe122abbe07f067f939ca3c480c5"

ATF_VERSION = "v2.5.1"
ATF_BRANCH = "socfpga_${ATF_VERSION}"

SRCREV = "66602dafe0614fbf2c1354e56167ff773ff04603"
