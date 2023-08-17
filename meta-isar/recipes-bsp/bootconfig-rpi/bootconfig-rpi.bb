# This software is a part of ISAR.
# Copyright (C) 2022 ilbers GmbH

DESCRIPTION = "Boot config for Raspberry PI boards"
MAINTAINER = "isar-users <isar-users@googlegroups.com>"

SRC_URI = "file://config.txt \
	   file://cmdline.txt.tmpl"

inherit dpkg-raw

TEMPLATE_VARS = "MACHINE_SERIAL BAUDRATE_TTY"
TEMPLATE_FILES = "cmdline.txt.tmpl"

# Exceptions for RPi1
SRC_URI:append:rpi = " file://postinst"
SRC_URI:remove:rpi = "file://cmdline.txt.tmpl"
TEMPLATE_FILES:remove:rpi = "cmdline.txt.tmpl"

PN = "bootconfig-${MACHINE}"

do_install() {
    install -v -d ${D}/boot/
    install -v -m 644 ${WORKDIR}/config.txt ${D}/boot/
    if [ -f "${WORKDIR}/cmdline.txt" ]; then
        install -v -m 644 ${WORKDIR}/cmdline.txt ${D}/boot/
    fi
}

COMPATIBLE_MACHINE = "rpi"
