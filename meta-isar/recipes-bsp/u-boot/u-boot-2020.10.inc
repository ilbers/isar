#
# Copyright (c) Siemens AG, 2018-2025
#
# SPDX-License-Identifier: MIT

inherit u-boot

SRC_URI += " \
    https://ftp.denx.de/pub/u-boot/u-boot-${PV}.tar.bz2 \
    "
SRC_URI[sha256sum] = "0d481bbdc05c0ee74908ec2f56a6daa53166cc6a78a0e4fac2ac5d025770a622"

S = "${WORKDIR}/u-boot-${PV}"
