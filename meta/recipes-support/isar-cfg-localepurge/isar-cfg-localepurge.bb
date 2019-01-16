# This software is a part of ISAR.

DESCRIPTION = "Isar configuration package for locale and localepurge"
MAINTAINER = "isar-users <isar-users@googlegroups.com>"
DEBIAN_DEPENDS = "localepurge"

SRC_URI = "file://postinst"

inherit dpkg-raw

LOCALE_GEN ?= "en_US.UTF-8 UTF-8\n\
               en_US ISO-8859-1\n"
LOCALE_DEFAULT ?= "en_US.UTF-8"

def get_locale_gen(d):
    locale_gen = d.getVar("LOCALE_GEN", True) or ""
    return '\n'.join(sorted(set(i.strip()
                                for i in locale_gen.split('\\n')
                                if i.strip())))

def get_dc_locale_gen(d):
    locale_gen = d.getVar("LOCALE_GEN", True) or ""
    return ', '.join(sorted(set(i.strip()
                                for i in locale_gen.split('\\n')
                                if i.strip())))

def get_nopurge(d):
    locale_gen = d.getVar("LOCALE_GEN", True) or ""
    return '\n'.join(sorted(set(i.strip()
                                for j in locale_gen.split('\\n')
                                if j.strip()
                                for i in (j.split()[0].split("_")[0],
                                          j.split()[0].split(".")[0],
                                          j.split()[0]))))

do_gen_config[stamp-extra-info] = "${DISTRO}-${DISTRO_ARCH}"
do_gen_config() {
	cat<<-__EOF__ > ${WORKDIR}/locale.gen
		${@get_locale_gen(d)}
	__EOF__
	cat<<-__EOF__ > ${WORKDIR}/locale.debconf
		locales     locales/locales_to_be_generated    multiselect ${@get_dc_locale_gen(d)}
		locales     locales/default_environment_locale select      ${LOCALE_DEFAULT}
	__EOF__
	cat<<-__EOF__ > ${WORKDIR}/locale.default
		LANG=${LOCALE_DEFAULT}
	__EOF__
	cat<<-__EOF__ > ${WORKDIR}/locale.nopurge
		#USE_DPKG
		MANDELETE
		DONTBOTHERNEWLOCALE
		#SHOWFREEDSPACE
		#QUICKNDIRTYCALC
		#VERBOSE
		${@get_nopurge(d)}
	__EOF__
}
addtask gen_config after do_unpack before do_install

do_install() {
	install -v -d ${D}/usr/lib/${PN}
	install -v -m 644 ${WORKDIR}/locale.debconf \
                          ${D}/usr/lib/${PN}/locale.debconf
	install -v -m 644 ${WORKDIR}/locale.gen \
                          ${D}/usr/lib/${PN}/locale.gen
	install -v -m 644 ${WORKDIR}/locale.default \
			  ${D}/usr/lib/${PN}/locale.default
	install -v -m 644 ${WORKDIR}/locale.nopurge \
                          ${D}/usr/lib/${PN}/locale.nopurge
}
