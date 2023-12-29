# This software is a part of ISAR.
# Copyright (C) 2024 ilbers GmbH

inherit dpkg

require recipes-bsp/barebox/barebox.inc

SRC_URI += "https://git.phytec.de/barebox/snapshot/barebox-${PV}.tar.bz2 \
            file://0001-ARM-fix-GCC-11.x-build-failures-for-ARMv7.patch \
            file://0001-of_dump-Add-a-simple-node-check-up.patch"

S = "${WORKDIR}/barebox-${PV}"

SRC_URI[sha256sum] = "1e11625e81f1e42e107ab550f557602d8ffbf013b9277112f5b243c93535642f"

BAREBOX_VERSION_EXTENSION = "-isar"
