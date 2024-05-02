# This software is a part of ISAR.
inherit dpkg-raw

DESCRIPTION = "Systemd service to regenerate sshd keys"
MAINTAINER = "isar-users <isar-users@googlegroups.com>"
DEBIAN_DEPENDS = "openssh-server, systemd"

DPKG_ARCH = "all"

SRC_URI = "file://postinst \
           file://sshd-regen-keys.service"
