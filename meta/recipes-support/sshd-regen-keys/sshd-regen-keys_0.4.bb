# This software is a part of ISAR.
inherit dpkg-raw

DESCRIPTION = "Systemd service to regenerate sshd keys"
MAINTAINER = "isar-users <isar-users@googlegroups.com>"
DEBIAN_DEPENDS = "openssh-server, systemd"

SRC_URI = "file://postinst \
           file://sshd-regen-keys.service"

do_install() {
    install -d -m 0755 "${D}/lib/systemd/system"
    install -m 0644 "${WORKDIR}/sshd-regen-keys.service" "${D}/lib/systemd/system/sshd-regen-keys.service"
}
