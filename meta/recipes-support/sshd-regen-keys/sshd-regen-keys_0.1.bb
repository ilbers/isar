# This software is a part of ISAR.
inherit dpkg-raw

DESCRIPTION = "Systemd service to regenerate sshd keys"
MAINTAINER = "isar-users <isar-users@googlegroups.com>"
DEBIAN_DEPENDS = "openssh-server, systemd"

SRC_URI = "file://postinst \
           file://sshd-regen-keys.service"

do_install() {
    install -v -d -m 755 "${D}/lib/systemd/system"
    install -v -m 644 "${WORKDIR}/sshd-regen-keys.service" "${D}/lib/systemd/system/sshd-regen-keys.service"
}
