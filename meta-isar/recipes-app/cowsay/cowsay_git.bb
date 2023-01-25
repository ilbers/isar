# This software is a part of ISAR.
# Copyright (c) Siemens AG, 2019
#
# SPDX-License-Identifier: MIT

inherit dpkg-gbp

SRC_URI = "git://salsa.debian.org/debian/cowsay.git;protocol=https;branch=master"
SRC_URI += "file://isar.patch"
SRCREV = "756f0c41fbf582093c0c1dff9ff77734716cb26f"
