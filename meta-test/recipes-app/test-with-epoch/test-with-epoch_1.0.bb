# This software is a part of Isar.
# Copyright (C) 2026 Siemens AG
#
# SPDX-License-Identifier: MIT

# Test that a .deb with an epoch and special characters ('+' and '~') in
# its version is properly handled by isar-apt (exercises URI percent-decoding).

inherit dpkg-raw

MAINTAINER = "isar-users <isar-users@googlegroups.com>"
DESCRIPTION = "Test package with epoch in version"

CHANGELOG_V = "1:1.0+test~1-1"
