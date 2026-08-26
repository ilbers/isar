# Example recipe for building the mainline kernel
#
# This software is a part of Isar.
# Copyright (c) Siemens AG, 2018-2025
#
# SPDX-License-Identifier: MIT

PN .= "-${DISTRO_ARCH}"

require recipes-kernel/linux/linux-mainline.inc
