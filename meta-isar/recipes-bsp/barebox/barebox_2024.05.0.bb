# This software is a part of ISAR.
# Copyright (C) 2022 ilbers GmbH

inherit dpkg

require recipes-bsp/barebox/barebox.inc

SRC_URI += "https://git.pengutronix.de/cgit/barebox/snapshot/barebox-${PV}.tar.gz \
            file://0001-of_dump-Add-a-simple-node-check-up.patch"

S = "${WORKDIR}/barebox-${PV}"

SRC_URI[sha256sum] = "f57cba0be683a7e8aca8a0090e42d5913a4efb8bce762d2648f12fd666e2ebc9"

BAREBOX_VERSION_EXTENSION = "-isar"
