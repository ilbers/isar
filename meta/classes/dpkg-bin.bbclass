inherit isar-base

DEBIAN_DEPENDS ?= ""
DEBIAN_MAINTAINER ?= "FIXME Unknown maintainer"

D = "${WORKDIR}/image/"

# Populate folder that will be picked up as package
do_install() {
	bbnote "Put your files for this package in ${D}"
}

addtask install after do_unpack before do_deb_package_prepare
# so we can put hooks in there already
do_install[dirs] = "${D}/DEBIAN"

do_deb_package_prepare() {
	cat<<-__EOF__ > ${D}/DEBIAN/control
		Package: ${PN}
		Architecture: `dpkg --print-architecture`
		Section: misc
		Priority: optional
		Maintainer: ${DEBIAN_MAINTAINER}
		Depends: `echo ${DEBIAN_DEPENDS} | tr '[:blank:]' ','`
		Version: ${PV}+isar
		Description: ${DESCRIPTION}
	__EOF__
	CONFFILES=${D}/DEBIAN/conffiles
	find ${D} -path '*/etc/*' | sed -e 's|^${D}||' > $CONFFILES
	test -s $CONFFILES || rm $CONFFILES
	for t in pre post
	do
		for a in inst rm
		do
			chmod -f +x ${D}/DEBIAN/${t}${a} || true
		done
	done
}

addtask deb_package_prepare after do_install before do_install_package

do_deb_package() {
	sudo chown -R root:root ${D}/DEBIAN/
	sudo dpkg-deb --build ${D} ${WORKDIR}
}

addtask deb_package after do_deb_package_prepare before do_install_package
