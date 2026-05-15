# This software is a part of Isar.
# Copyright (C) 2026 Siemens AG
#
# SPDX-License-Identifier: MIT

# Test that a .deb without a Priority field can be added to the repository.
# The debianize class sets Priority in the Source stanza of debian/control;
# we strip it here so the resulting .deb has no Priority metadata, exercising
# the prio_opt fallback in repository.bbclass.

inherit dpkg-raw

do_prepare_build:append() {
    sed -i '/^Priority:/d' ${S}/debian/control
}
