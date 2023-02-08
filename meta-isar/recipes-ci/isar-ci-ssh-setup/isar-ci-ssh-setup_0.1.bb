# This software is a part of ISAR.

DESCRIPTION = "Setup user with non-interactive SSH access"
MAINTAINER = "Uladzimir Bely <uladzimir.bely@ilbers.de>"

SRC_URI = " \
    file://postinst \
"

DEPENDS += "sshd-regen-keys"
DEBIAN_DEPENDS = "adduser, apt (>= 0.4.2), network-manager, sshd-regen-keys"

inherit dpkg-raw

do_install() {
    # Install authorized SSH keys
    install -v -d ${D}/var/lib/isar-ci/.ssh/
    install -v -m 644 ${TESTSUITEDIR}/keys/ssh/id_rsa.pub ${D}/var/lib/isar-ci/.ssh/authorized_keys

    # Manage all interfaces (including ethernet) by NetworkManager
    install -D -m 644 /dev/null ${D}/etc/NetworkManager/conf.d/10-globally-managed-devices.conf
}
