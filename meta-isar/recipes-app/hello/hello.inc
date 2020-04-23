# This software is a part of ISAR.
# Copyright (c) Siemens AG, 2019
#
# SPDX-License-Identifier: MIT

inherit dpkg

# This will fetch and unpack the sources from upstream Debian.
# Note that you can also choose a version but have to pick the exact one
# i.e. "apt://hello=2.10-2".
SRC_URI = "apt://${PN}"

MAINTAINER = "isar-users <isar-users@googlegroups.com>"
CHANGELOG_V = "<orig-version>+isar"

do_prepare_build() {
	deb_add_changelog
	# this seems to be a build dep missing in the upstream control file
	if ! grep texinfo ${S}/debian/control; then
		sed -i -e 's/Build-Depends:/Build-Depends: texinfo,/g' ${S}/debian/control
	fi
}

dpkg_runbuild_prepend() {
	if [ ${ISAR_CROSS_COMPILE} -eq 1 ]; then
		export DEB_BUILD_OPTIONS="nocheck"
	fi
}
