#
# Copyright (c) Siemens AG, 2020
#
# SPDX-License-Identifier: MIT

require recipes-bsp/optee-os/optee-os-custom.inc

SRC_URI += "https://github.com/OP-TEE/optee_os/archive/${PV}.tar.gz"
SRC_URI[sha256sum] = "d30776ab051b701cdd2b71d32ff5cd54285a688440cc90aefd14b4f0f6495d7c"

S = "${WORKDIR}/optee_os-${PV}"

DEBIAN_BUILD_DEPENDS += ", device-tree-compiler"

OPTEE_PLATFORM = "stm32mp1"
OPTEE_EXTRA_BUILDARGS = " \
    ARCH=arm CFG_EMBED_DTB_SOURCE_FILE=stm32mp157c-ev1.dts \
    CFG_TEE_CORE_LOG_LEVEL=2"
OPTEE_BINARIES = "tee-header_v2.stm32 tee-pageable_v2.stm32 tee-pager_v2.stm32"
