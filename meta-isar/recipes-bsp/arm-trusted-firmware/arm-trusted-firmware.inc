

inherit dpkg
FILESEXTRAPATHS_prepend := "${FILE_DIRNAME}/files:"
SRC_URI += "file://debian/"

DESCRIPTION = "ARM Trusted Firmware"

LICENSE = "BSD"
LIC_FILES_CHKSUM ?= "file://docs/license.rst;md5=189505435dbcdcc8caa63c46fe93fa89"

ATF_PROT ?= "https"
ATF_BRANCH ?= "socfpga_v2.3"
ATF_REPO ?= "git://github.com/altera-opensource/arm-trusted-firmware.git"

SRC_URI += "${ATF_REPO};protocol=${ATF_PROT};branch=${ATF_BRANCH};destsuffix=${P}"

MACHINE = "agilex"

TF_A_NAME = "${MACHINE}"
TF_A_PLATFORM ?= "agilex"
TF_A_EXTRA_BUILDARGS ?= ""
TF_A_BINARIES ?= "release/bl31.bin"

DEBIAN_BUILD_DEPENDS ?= ""

PROVIDES += "arm-trusted-firmware"

TEMPLATE_FILES = "debian/control.tmpl debian/rules.tmpl"
TEMPLATE_VARS += "TF_A_NAME DEBIAN_BUILD_DEPENDS TF_A_PLATFORM TF_A_EXTRA_BUILDARGS"

do_prepare_build() {
    cp -r ${WORKDIR}/debian ${S}/

    deb_add_changelog

    rm -f ${S}/debian/arm-trusted-firmware-${TF_A_NAME}.install
    for binary in ${TF_A_BINARIES}; do
        echo "build/${TF_A_PLATFORM}/$binary /usr/lib/arm-trusted-firmware/${TF_A_NAME}/" >> \
            ${S}/debian/arm-trusted-firmware-${TF_A_NAME}.install
    done
}

