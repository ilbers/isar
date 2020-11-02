# Kselftest package
#
# This software is a part of ISAR.
# Copyright (c) Mentor Graphics, a Siemens business, 2020
#
# SPDX-License-Identifier: MIT

require recipes-kernel/kselftest/kselftest.inc

SRC_URI += "https://cdn.kernel.org/pub/linux/kernel/v5.x/linux-${PV}.tar.xz"
SRC_URI[sha256sum] = "f125d79c8f6974213638787adcad6b575bbd35a05851802fd83f622ec18ff987"
