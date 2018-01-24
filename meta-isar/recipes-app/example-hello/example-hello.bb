# Sample application
#
# This software is a part of ISAR.
# Copyright (C) 2015-2018 ilbers GmbH

DESCRIPTION = "Sample application for ISAR"

LICENSE = "gpl-2.0"
LIC_FILES_CHKSUM = "file://${LAYERDIR_isar}/licenses/COPYING.GPLv2;md5=751419260aa954499f7abaabaa882bbe"

PV = "0.2+7bf716d2"

SRC_URI = "git://github.com/ilbers/hello.git;protocol=https"
SRCREV = "7bf716d22dbdb5a83edf0fe6134c0500f1a8b1f0"

SRC_DIR = "git"

inherit dpkg
