# Sample application
#
# This software is a part of ISAR.
# Copyright (C) 2015-2016 ilbers GmbH

DESCRIPTION = "Sample application for ISAR"

LICENSE = "gpl-2.0"
LIC_FILES_CHKSUM = "file://${LAYERDIR_isar}/licenses/COPYING.GPLv2;md5=751419260aa954499f7abaabaa882bbe"

PV = "1.0"

SRC_URI = "git://github.com/ilbers/hello.git;protocol=https"
SRCREV = "ad7065ecc4840cc436bfcdac427386dbba4ea719"

SRC_DIR = "git"

inherit dpkg-src
