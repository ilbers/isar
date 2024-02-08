# Sample shared library
#
# This software is a part of ISAR.
# Copyright (C) 2017-2024 ilbers GmbH

DESCRIPTION = "Sample shared library for ISAR"

LICENSE = "gpl-2.0"
LIC_FILES_CHKSUM = "file://${LAYERDIR_core}/licenses/COPYING.GPLv2;md5=751419260aa954499f7abaabaa882bbe"

PV = "0.3-f4a5669"

SRC_URI = "git://github.com/ilbers/libhello.git;protocol=https;branch=master;destsuffix=${P}"
SRCREV = "f4a5669c8c63f7cae8ff268cbf298dd45865b974"

inherit dpkg

# Example of using alternative sbuild chroot
SBUILD_FLAVOR="db2m"
