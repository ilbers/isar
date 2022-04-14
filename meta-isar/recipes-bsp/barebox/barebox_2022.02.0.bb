# This software is a part of ISAR.
# Copyright (C) 2022 ilbers GmbH

inherit dpkg

require recipes-bsp/barebox/barebox.inc

SRC_URI += "https://git.pengutronix.de/cgit/barebox/snapshot/barebox-${PV}.tar.gz \
            file://0001-of_dump-Add-a-simple-node-check-up.patch"

SRC_URI[sha256sum] = "01fb3799840bde34014981557361dcae1db23764708bb7b151ec044eb022fbe8"

BAREBOX_VERSION_EXTENSION = "-isar"
