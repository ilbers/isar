# This software is a part of Isar.
# Copyright (C) Siemens AG, 2024-2025
#
# SPDX-License-Identifier: MIT

DESCRIPTION = "systemd service to run target bootstrapper on ${TARGET_BOOTSTRAPPER_TTY_SERVICES}"
MAINTAINER ?= "isar-users <isar-users@googlegroups.com>"

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
    file://generate-target-bootstrapper-dropin.sh \
    file://target-bootstrapper-generate-dropin.service \
    "

TEMPLATE_FILES = "postinst.tmpl"
TEMPLATE_VARS = "TARGET_BOOTSTRAPPER_TTY_SERVICES"

DEPENDS += " target-bootstrapper"
DEBIAN_DEPENDS = "target-bootstrapper"

do_install[cleandirs] = "${D}/usr/lib/systemd/system/ ${D}/usr/libexec"
do_install() {
    for svc_name in ${TARGET_BOOTSTRAPPER_TTY_SERVICES}
    do
        install -d -m 0755 ${D}/usr/lib/systemd/system/${svc_name}.service.d/
        install -m 0644 ${WORKDIR}/target-bootstrapper.override.conf ${D}/usr/lib/systemd/system/${svc_name}.service.d/10-target-bootstrapper.override.conf
    done

    # Install script and service for runtime detection of serial devices
    install -d -m 0755 ${D}/usr/libexec/${PN}/
    install -m 0755 ${WORKDIR}/generate-target-bootstrapper-dropin.sh ${D}/usr/libexec/${PN}/
    install -m 0644 ${WORKDIR}/target-bootstrapper-generate-dropin.service ${D}/usr/lib/systemd/system/

    # Install override template for runtime use by the detection script
    install -m 0644 ${WORKDIR}/target-bootstrapper.override.conf ${D}/usr/lib/target-bootstrapper.override.conf
}
