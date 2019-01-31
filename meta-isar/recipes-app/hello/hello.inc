# This software is a part of ISAR.
# Copyright (c) Siemens AG, 2019
#
# SPDX-License-Identifier: MIT

inherit dpkg

# this will fetch and unpack the sources from upstream debian
SRC_URI = "apt://${PN}=${PV}"

MAINTAINER = "isar-users <isar-users@googlegroups.com>"
CHANGELOG_V = "${PV}-99+isar"

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
