# Sample application using dpkg-bin, which turns a folder (${D}) of
# files into a .deb 
#
# This software is a part of ISAR.

DESCRIPTION = "Sample bin application for ISAR"
DEBIAN_MAINTAINER = "Your name here <you@domain.com>"

inherit dpkg-bin

do_install() {
	bbnote "Creating ${PN} binary"
	echo "#!/bin/sh" > ${WORKDIR}/${PN}
	echo "echo Hello World! ${PN}_${PV}" >> ${WORKDIR}/${PN}

	bbnote "Putting ${PN} into overlay"
	install -v -d ${D}/usr/local/bin/
	install -v -m 755 ${WORKDIR}/${PN} ${D}/usr/local/bin/${PN}

	bbnote "Now copy ${FILESDIR}/README to overlay"
	install -v -d ${D}/usr/local/doc/
	install -v -m 644 ${FILESDIR}/README ${D}/usr/local/doc/README-${P}

	bbnote "Now for a debian hook, see dpkg-deb"
	install -v -m 755 ${FILESDIR}/postinst ${D}/DEBIAN/postinst
}
