# Custom kernel module recipe include
#
# This software is a part of ISAR.
# Copyright (c) Siemens AG, 2018
#
# SPDX-License-Identifier: MIT

FILESPATH =. "${LAYERDIR_core}/recipes-kernel/linux-module/files:"

DESCRIPTION ?= "Custom kernel module ${PN}"

DEPENDS += "linux-headers-${KERNEL_NAME}"

SRC_URI += "file://debian/"

AUTOLOAD ?= "0"

inherit dpkg

dpkg_runbuild_prepend() {
    cp -r ${WORKDIR}/debian ${WORKDIR}/${S}/
    sed -i -e 's/@PN@/${PN}/g' -e 's/@PV@/${PV}/g' \
           -e 's/@KERNEL_NAME@/${KERNEL_NAME}/g' \
           -e 's/@DESCRIPTION@/${DESCRIPTION}/g' \
        ${WORKDIR}/${S}/debian/changelog ${WORKDIR}/${S}/debian/control

    if [ ${AUTOLOAD} = "1" ]; then
        echo "echo ${PN} >> /etc/modules" >> ${WORKDIR}/${S}/debian/postinst
        chmod +x ${WORKDIR}/${S}/debian/postinst
    fi
}
