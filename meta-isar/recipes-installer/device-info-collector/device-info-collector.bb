# This software is a part of ISAR.
# Copyright (C) Siemens AG, 2024-2025
#
# SPDX-License-Identifier: MIT

inherit dpkg-raw

DEBIAN_DEPENDS += "\
	, dmidecode \
	, lshw, pci.ids, usb.ids \
	, pciutils \
	, usbutils \
	, util-linux \
	"

SRC_URI += " \
	file://usr/bin/device-info-collector.sh \
	"

do_install[cleandirs] = " \
	${D}/usr/bin/ \
	${D}/usr/lib/device-info-collector/ \
	${D}/install/device-infos/ \
	"
do_install() {
	install -m 0755  ${WORKDIR}/usr/bin/device-info-collector.sh ${D}/usr/bin/device-info-collector.sh
}
