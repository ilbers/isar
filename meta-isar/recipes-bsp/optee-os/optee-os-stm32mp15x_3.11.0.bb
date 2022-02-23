#
# Copyright (c) Siemens AG, 2020
#
# SPDX-License-Identifier: MIT

require recipes-bsp/optee-os/optee-os-custom.inc

SRC_URI += "https://github.com/OP-TEE/optee_os/archive/${PV}.tar.gz"
SRC_URI[sha256sum] = "3c34eda1052fbb9ed36fcfdfaecfd2685023b9290670c1a5982f8a0457bfd2cb"

S = "${WORKDIR}/optee_os-${PV}"

DEBIAN_BUILD_DEPENDS += ", device-tree-compiler"

OPTEE_PLATFORM = "stm32mp1"
OPTEE_EXTRA_BUILDARGS = " \
    ARCH=arm CFG_EMBED_DTB_SOURCE_FILE=stm32mp157c-ev1.dts \
    CFG_TEE_CORE_LOG_LEVEL=2"
OPTEE_BINARIES = "tee-header_v2.stm32 tee-pageable_v2.stm32 tee-pager_v2.stm32"

# Set version manually to PV, the tarball does not contain any hint.
# Alternative: pull from git and add git as build dependency.
dpkg_runbuild_prepend() {
    grep -q "^export TEE_IMPL_VERSION" ${S}/debian/rules ||
        cat << EOF >> ${S}/debian/rules

export TEE_IMPL_VERSION=${PV}
EOF
}
