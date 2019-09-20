# This software is a part of ISAR.
# Copyright (C) 2017-2019 Siemens AG
#
# SPDX-License-Identifier: MIT

inherit dpkg

DEBIAN_DEPENDS ?= ""
MAINTAINER ?= "Unknown maintainer <unknown@example.com>"

D = "${S}"

# Populate folder that will be picked up as package
do_install() {
	bbnote "Put your files for this package in ${D}"
}

do_install[cleandirs] = "${D}"
addtask install after do_unpack before do_prepare_build

do_prepare_build[cleandirs] += "${D}/debian"
do_prepare_build() {
	cd ${D}
	find . -maxdepth 1 ! -name .. -and ! -name . -and ! -name debian | \
		sed 's:^./::' > ${WORKDIR}/${PN}.install
	mv ${WORKDIR}/${PN}.install ${D}/debian/

	deb_debianize
}
