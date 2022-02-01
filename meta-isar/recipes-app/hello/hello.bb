# This software is a part of ISAR.
# Copyright (c) Siemens AG, 2019
#
# SPDX-License-Identifier: MIT

inherit dpkg

# This will fetch and unpack the sources from upstream Debian.
# Note that you can also choose a version but have to pick the exact one
# i.e. "apt://hello=2.10-2".
# You may also select the desired release in case multiples are configured and
# you do want to pin the version: "apt://hello/buster".
SRC_URI = "apt://${PN}"

MAINTAINER = "isar-users <isar-users@googlegroups.com>"
CHANGELOG_V = "<orig-version>+isar"

DEB_BUILD_OPTIONS += "${@ 'nocheck' if d.getVar('ISAR_CROSS_COMPILE', True) == '1' else '' }"

do_prepare_build() {
	deb_add_changelog
	# this seems to be a build dep missing in the upstream control file
	if ! grep texinfo ${S}/debian/control; then
		sed -i -e 's/Build-Depends:/Build-Depends: texinfo,/g' ${S}/debian/control
	fi
}
