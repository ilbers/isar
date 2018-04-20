# Sample application
#
# This software is a part of ISAR.
# Copyright (C) 2015-2018 ilbers GmbH

DESCRIPTION = "Sample application for ISAR"

LICENSE = "gpl-2.0"
LIC_FILES_CHKSUM = "file://${LAYERDIR_isar}/licenses/COPYING.GPLv2;md5=751419260aa954499f7abaabaa882bbe"

PV = "0.2-86cc719"

# NOTE: the following line duplicates the content in 'debian/control', but
#       for now it's the only way to correctly build bitbake pipeline.
DEPENDS += "libhello"

SRC_URI = " \
    git://github.com/ilbers/hello.git;protocol=https;destsuffix=${P} \
    file://0001-Add-some-help.patch \
    file://yet-another-change.txt;apply=yes;striplevel=0"
SRCREV = "86cc719b3359adc3c4e243387feba50360a860f3"

inherit dpkg
