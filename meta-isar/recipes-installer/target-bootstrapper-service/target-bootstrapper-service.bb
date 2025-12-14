# This software is a part of ISAR.
# Copyright (C) Siemens AG, 2024-2025
#
# SPDX-License-Identifier: MIT

DESCRIPTION = "systemd service to run target bootstrapper on ${TARGET_BOOTSTRAPPER_TTY_SERVICES}"

TARGET_BOOTSTRAPPER_TTY_SERVICES ??= "\
    getty@tty1 \
    serial-getty@ttyS0 \
    "

python(){
    if not d.getVar('TARGET_BOOTSTRAPPER_TTY_SERVICES'):
        bb.error("No ttys for target bootstrapper configured - review TARGET_BOOTSTRAPPER_TTY_SERVICES setting")

    if (bb.utils.to_boolean(d.getVar('INSTALLER_UNATTENDED')) and
        len(d.getVar('TARGET_BOOTSTRAPPER_TTY_SERVICES').split()) != 1):
        bb.warn("Multiple ttys are configured for target bootstrapper in unattended mode. - potential race condition detected!")
}

inherit dpkg-raw

SRC_URI = "\
    file://postinst.tmpl \
    file://target-bootstrapper.override.conf \
    "

TEMPLATE_FILES = "postinst.tmpl"
TEMPLATE_VARS = "TARGET_BOOTSTRAPPER_TTY_SERVICES"

DEPENDS += " target-bootstrapper"
DEBIAN_DEPENDS = "target-bootstrapper"

do_install[cleandirs] = "${D}/usr/lib/systemd/system/"
do_install() {
    for svc_name in ${TARGET_BOOTSTRAPPER_TTY_SERVICES}
    do
        mkdir -p ${D}/usr/lib/systemd/system/${svc_name}.service.d/
        install -m 0644 ${WORKDIR}/target-bootstrapper.override.conf ${D}/usr/lib/systemd/system/${svc_name}.service.d/10-target-bootstrapper.override.conf
    done
}
