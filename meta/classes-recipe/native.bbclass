# This software is a part of Isar.
# Copyright (C) 2023 Siemens AG
#
# SPDX-License-Identifier: MIT

################################################################################
# package recipe modifications when building *-native:
################################################################################

PACKAGE_ARCH:class-native = "${HOST_ARCH}"

# Must match what crossvars.bbclass derives from PACKAGE_ARCH above, as
# sstate.bbclass already reads BUILD_ARCH before crossvars.bbclass sets it.
BUILD_ARCH:class-native = "${HOST_ARCH}"
