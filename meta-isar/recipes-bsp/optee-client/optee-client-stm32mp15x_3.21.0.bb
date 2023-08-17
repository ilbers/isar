#
# Copyright (c) Siemens AG, 2023
#
# Authors:
#  Su Bao Cheng <baocheng.su@siemens.com>
#
# SPDX-License-Identifier: MIT
#

require recipes-bsp/optee-client/optee-client-custom.inc

SRC_URI += "https://github.com/OP-TEE/optee_client/archive/${PV}.tar.gz;downloadfilename=optee_client-${PV}.tar.gz"
SRC_URI[sha256sum] = "368164a539b85557d2079fa6cd839ec444869109f96de65d6569e58b0615d026"

S = "${WORKDIR}/optee_client-${PV}"

# Use RPMB emulation
RPMB_EMU = "1"

COMPATIBLE_MACHINE = "stm32mp15x"
