# Example recipe for building a custom module
#
# This software is a part of ISAR.
# Copyright (c) Siemens AG, 2018
#
# SPDX-License-Identifier: MIT

inherit linux-module

SRC_URI += "file://src"

S = "${WORKDIR}/src"

AUTOLOAD = "example-module"
