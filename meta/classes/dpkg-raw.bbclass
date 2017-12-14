# This software is a part of ISAR.
# Copyright (C) 2017 Siemens AG

inherit dpkg-base

DEBIAN_DEPENDS ?= ""
MAINTAINER ?= "FIXME Unknown maintainer"

D = "${WORKDIR}/image/"

# Populate folder that will be picked up as package
do_install() {
	bbnote "Put your files for this package in ${D}"
}

do_install[stamp-extra-info] = "${DISTRO}-${DISTRO_ARCH}"
addtask install after do_unpack before do_deb_package_prepare

# so we can put hooks etc. in there already
do_install[dirs] = "${D}/DEBIAN"

do_deb_package_prepare() {
	cat<<-__EOF__ > ${D}/DEBIAN/control
		Package: ${PN}
		Architecture: ${DISTRO_ARCH}
		Section: misc
		Priority: optional
		Maintainer: ${MAINTAINER}
		Version: ${PV}+isar
		Description: ${DESCRIPTION}
	__EOF__
	[ "${DEBIAN_DEPENDS}" != "" ] && echo "Depends: ${DEBIAN_DEPENDS}" >> \
		${D}/DEBIAN/control
	for t in pre post
	do
		for a in inst rm
		do
			chmod -f +x ${D}/DEBIAN/${t}${a} || true
		done
	done
}

do_deb_package_prepare[stamp-extra-info] = "${DISTRO}-${DISTRO_ARCH}"
addtask deb_package_prepare after do_install before do_deb_package_conffiles

do_deb_package_conffiles() {
	CONFFILES=${D}/DEBIAN/conffiles
	find ${D} -type f -path '*/etc/*' | sed -e 's|^${D}|/|' >> $CONFFILES
	test -s $CONFFILES || rm $CONFFILES
}

do_deb_package_conffiles[stamp-extra-info] = "${DISTRO}-${DISTRO_ARCH}"
addtask deb_package_conffiles after do_deb_package_prepare before do_build

dpkg_runbuild() {
	sudo chown -R root:root ${D}/DEBIAN/
	sudo chroot ${BUILDCHROOT_DIR} dpkg-deb --build ${PP}/image ${PP}
}
