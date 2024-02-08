# Sample application
#
# This software is a part of ISAR.
# Copyright (C) 2015-2024 ilbers GmbH

DESCRIPTION = "Sample application for ISAR"

LICENSE = "gpl-2.0"
LIC_FILES_CHKSUM = "file://${LAYERDIR_core}/licenses/COPYING.GPLv2;md5=751419260aa954499f7abaabaa882bbe"

PV = "0.5-b48d156"

# NOTE: the following line duplicates the content in 'debian/control', but
#       for now it's the only way to correctly build bitbake pipeline.
DEPENDS += "libhello"

SRC_URI = " \
    git://github.com/ilbers/hello.git;protocol=https;branch=master;destsuffix=${P} \
    file://subdir/0001-Add-some-help.patch \
    file://yet-another-change.txt;apply=yes;striplevel=0"
SRCREV = "b48d15629667377f544e71c7310b80a71d00d9dd"

inherit dpkg

# Example of using alternative sbuild chroot
SBUILD_FLAVOR="db2m"
