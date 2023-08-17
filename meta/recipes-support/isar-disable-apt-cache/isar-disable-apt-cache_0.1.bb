# This software is a part of ISAR.
inherit dpkg-raw

DESCRIPTION = "Configuration to disable apt cache"
MAINTAINER = "isar-users <isar-users@googlegroups.com>"

SRC_URI = "file://${BPN}"

do_install[cleandirs] += "${D}/etc/apt/apt.conf.d/"

do_install() {
    install -v -m 644 "${WORKDIR}/${BPN}" "${D}/etc/apt/apt.conf.d/99${BPN}"
}
