# This software is a part of Isar.
# Copyright (C) ilbers GmbH, 2026
#
# SPDX-License-Identifier: MIT

inherit dpkg-raw

PN:append = "-${MACHINE}"

KERNEL_IMAGE_PKG ??= "${@ ("linux-image-" + d.getVar("KERNEL_NAME")) if d.getVar("KERNEL_NAME") else ""}"

DEPENDS = "${KERNEL_IMAGE_PKG}"
DEBIAN_BUILD_DEPENDS = "${KERNEL_IMAGE_PKG}"

DPKG_ARCH = "${PACKAGE_ARCH}"

do_prepare_build:append() {
    for dtb in ${DTB_FILES}; do
        dir=debian/${PN}/usr/lib/${PN}/$(dirname ${dtb})
        cat <<EOF >> ${S}/debian/rules
	mkdir -p ${dir}
	find /usr/lib/linux-image* -path "*${dtb}" -print -exec cp {} ${dir} \;
EOF
    done
}

DTB_PACKAGE ??= "${PN}_${CHANGELOG_V}_${DISTRO_ARCH}.deb"

do_deploy[dirs] = "${DEPLOY_DIR_IMAGE}"
do_deploy[cleandirs] = "${WORKDIR}/deploy"
do_deploy() {
    dpkg --fsys-tarfile ${WORKDIR}/${DTB_PACKAGE} | \
    tar --wildcards --extract --directory ${WORKDIR}/deploy ./usr/lib/${PN}
    for dtb in ${DTB_FILES}; do
        mkdir -p ${DEPLOY_DIR_IMAGE}/$(dirname ${dtb})
        find ${WORKDIR}/deploy/usr/lib/${PN} -path "*${dtb}" -print \
            -exec cp {} ${DEPLOY_DIR_IMAGE}/${dtb} \;
    done
}

addtask deploy before do_deploy_deb after do_dpkg_build
