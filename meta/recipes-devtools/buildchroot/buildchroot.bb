# Multistrap development root filesystem
#
# Copyright (C) 2015-2016 ilbers GmbH

DESCRIPTION = "Multistrap development root"

LICENSE = "gpl-2.0"
LIC_FILES_CHKSUM = "file://LICENSE;md5=b234ee4d69f5fce4486a80fdaf4a4263"

PV = "1.0"

SRC_URI = "\
    file://hooks/completion_chroot.sh \
    file://multistrap.conf            \
    file://setup.sh                   \
    file://configscript.sh            \
    file://LICENSE                    \
"

DEVROOT = "${WORKDIR}/../devroot/rootfs"

do_build() {
    #copy config files
    install -d ${DEVROOT}
    install -d ${WORKDIR}/hooks
    install -m 644 ${THISDIR}/${PN}/multistrap.conf ${WORKDIR}
    install -m 755 ${THISDIR}/${PN}/setup.sh ${WORKDIR}
    install -m 755 ${THISDIR}/${PN}/configscript.sh ${WORKDIR}
    install -m 755 ${THISDIR}/${PN}/hooks/* ${WORKDIR}/hooks

    sudo multistrap -a armhf -d "${DEVROOT}" -f "${WORKDIR}/multistrap.conf" || true
    sudo install -m 755 /usr/bin/qemu-arm-static ${DEVROOT}/usr/bin
}
