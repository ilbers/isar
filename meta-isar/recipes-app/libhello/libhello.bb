# Sample shared library
#
# This software is a part of ISAR.
# Copyright (C) 2017-2018 ilbers GmbH

DESCRIPTION = "Sample shared library for ISAR"

LICENSE = "gpl-2.0"
LIC_FILES_CHKSUM = "file://${LAYERDIR_isar}/licenses/COPYING.GPLv2;md5=751419260aa954499f7abaabaa882bbe"

PV = "0.1-98f2e41"

SRC_URI = "git://github.com/ilbers/libhello.git;protocol=https"
SRCREV = "98f2e41e7d05ab8d19b0c5d160b104b725c8fd93"

SRC_DIR = "git"

inherit dpkg
