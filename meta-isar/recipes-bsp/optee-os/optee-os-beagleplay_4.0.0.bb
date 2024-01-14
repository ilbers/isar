#
# Copyright (c) Siemens AG, 2023-2024
#
# SPDX-License-Identifier: MIT

require recipes-bsp/optee-os/optee-os-custom.inc

SRC_URI += "https://github.com/OP-TEE/optee_os/archive/${PV}.tar.gz;downloadfilename=optee_os-${PV}.tar.gz"
SRC_URI[sha256sum] = "2c2c9525b36c96dfad6216520721b8e9663e6cacc61d0108a0c8bffc0ea175f1"

S = "${WORKDIR}/optee_os-${PV}"

DEBIAN_BUILD_DEPENDS += ", python3-cryptography:native"

OPTEE_PLATFORM = "k3"
OPTEE_EXTRA_BUILDARGS = " \
    TEE_IMPL_VERSION=${PV} \
    CFG_ARM64_core=y CFG_USER_TA_TARGETS=ta_arm64"
