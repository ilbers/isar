# Example recipe for building a custom module
#
# This software is a part of ISAR.
# Copyright (c) Siemens AG, 2018
#
# SPDX-License-Identifier: MIT

include recipes-kernel/linux-module/module.inc

SRC_URI += "file://src"

S = "src"

AUTOLOAD = "1"
