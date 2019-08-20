# Root filesystem for packages building
#
# This software is a part of ISAR.
# Copyright (C) 2015-2018 ilbers GmbH

DESCRIPTION = "Isar development filesystem for target"

BUILDCHROOT_VARIANT = "target"

require buildchroot.inc

BUILDCHROOT_PREINSTALL ?= " \
    ${BUILDCHROOT_PREINSTALL_COMMON} \
    gcc \
    build-essential"
