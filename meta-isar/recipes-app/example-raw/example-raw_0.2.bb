# Sample application using dpkg-raw, which turns a folder (${D}) of
# files into a .deb
#
# This software is a part of ISAR.

DESCRIPTION = "Sample application for ISAR"
MAINTAINER = "Your name here <you@domain.com>"
DEBIAN_DEPENDS = "apt (>= 0.4.2), passwd"

SRC_URI = "file://README \
	   file://postinst"

inherit dpkg-raw

do_install() {
	bbnote "Creating ${PN} binary"
	echo "#!/bin/sh" > ${WORKDIR}/${PN}
	echo "echo Hello ISAR! ${PN}_${PV}" >> ${WORKDIR}/${PN}

	bbnote "Putting ${PN} into package"
	install -v -d ${D}/usr/local/bin/
	install -v -m 755 ${WORKDIR}/${PN} ${D}/usr/local/bin/${PN}

	bbnote "Now copy ${FILESDIR}/README into package"
	install -v -d ${D}/usr/local/doc/
	install -v -m 644 ${WORKDIR}/README ${D}/usr/local/doc/README-${P}

	bbnote "Now for a fake config file"
	echo "# empty config file" > ${WORKDIR}/${PN}.conf
	install -v -d ${D}/usr/local/etc/
	install -v -m 644 ${WORKDIR}/${PN}.conf ${D}/usr/local/etc/${PN}.conf
}
