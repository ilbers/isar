# This software is a part of ISAR.
inherit dpkg-raw

DESCRIPTION = "Systemd service to regenerate sshd keys"
MAINTAINER = "isar-users <isar-users@googlegroups.com>"
DEBIAN_DEPENDS = "openssh-server, systemd"

SRC_URI = "file://postinst \
           file://sshd-regen-keys.service \
           file://sshd-regen-keys.sh"

do_install[cleandirs] = "${D}/lib/systemd/system \
                         ${D}/usr/sbin"
do_install() {
    install -v -m 644 "${WORKDIR}/sshd-regen-keys.service" "${D}/lib/systemd/system/sshd-regen-keys.service"
    install -v -m 755 "${WORKDIR}/sshd-regen-keys.sh" "${D}/usr/sbin/sshd-regen-keys.sh"
}
