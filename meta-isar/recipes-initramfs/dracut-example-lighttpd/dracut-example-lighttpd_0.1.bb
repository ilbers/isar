#
# Copyright (c) Siemens AG, 2025
#
# Authors:
#  Quirin Gylstorff <quirin.gylstorff@siemens.com>
#
# SPDX-License-Identifier: MIT
#
# This example adds the lighttpd server to the dracut initrd

inherit dracut-module

# Additional install instructions
DRACUT_INSTALL_CONTENT_FILE_NAME = "install.sh"

DEBIAN_DEPENDS:append = ",lighttpd, kbd,  passwd, \
                   dracut-network, dbus-daemon, iproute2, \
                   dracut-example-lighttpd, systemd-sysv, systemd-resolved, systemd-timesyncd"

DEBIAN_DEPENDS:append:trixie = ", systemd-cryptsetup"


SRC_URI += "file://lighttpd.conf \
            file://lighttpd.service \
            file://sysuser-lighttpd.conf \
            "

# lighttpd binaries
DRACUT_REQUIRED_BINARIES = "lighttpd \
                            lighttpd-angel \
                            lighttpd-disable-mod \
                            lighttpd-enable-mod \
                            lighty-enable-mod \
                            "
# we need networking
DRACUT_MODULE_DEPENDENCIES = "systemd-network-management"

do_install[cleandirs] += "${D}/usr/lib/sysusers.d/"
do_install() {
        install -m 666 ${WORKDIR}/lighttpd.conf ${DRACUT_MODULE_PATH}
        install -m 666 ${WORKDIR}/lighttpd.service ${DRACUT_MODULE_PATH}
        # install sysuser to be used by dracut
        install -m 666 ${WORKDIR}/sysuser-lighttpd.conf ${D}/usr/lib/sysusers.d/lighttpd.conf
}
