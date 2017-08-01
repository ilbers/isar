# Root filesystem for packages building
#
# This software is a part of ISAR.
# Copyright (C) 2015-2016 ilbers GmbH

DESCRIPTION = "Multistrap development filesystem"

LICENSE = "gpl-2.0"
LIC_FILES_CHKSUM = "file://${LAYERDIR_isar}/licenses/COPYING.GPLv2;md5=751419260aa954499f7abaabaa882bbe"

PV = "1.0"

BUILDCHROOT_PREINSTALL ?= "gcc \
                           make \
                           build-essential \
                           debhelper \
                           autotools-dev \
                           dpkg \
                           locales \
                           docbook-to-man \
                           apt \
                           automake"

WORKDIR = "${TMPDIR}/work/${PF}/${DISTRO}"

do_build[stamp-extra-info] = "${DISTRO}"

do_build() {
    install -d -m 755 ${WORKDIR}/hooks_multistrap

    # Copy config files
    install -m 644 ${FILESDIR}/multistrap.conf.in ${WORKDIR}/multistrap.conf
    install -m 755 ${FILESDIR}/configscript.sh ${WORKDIR}
    install -m 755 ${FILESDIR}/setup.sh ${WORKDIR}
    install -m 755 ${FILESDIR}/download_dev-random ${WORKDIR}/hooks_multistrap/

    # Adjust multistrap config
    sed -i 's|##BUILDCHROOT_PREINSTALL##|${BUILDCHROOT_PREINSTALL}|' ${WORKDIR}/multistrap.conf
    sed -i 's|##DISTRO##|${DISTRO}|' ${WORKDIR}/multistrap.conf
    sed -i 's|##DISTRO_APT_SOURCE##|${DISTRO_APT_SOURCE}|' ${WORKDIR}/multistrap.conf
    sed -i 's|##DISTRO_SUITE##|${DISTRO_SUITE}|' ${WORKDIR}/multistrap.conf
    sed -i 's|##DISTRO_COMPONENTS##|${DISTRO_COMPONENTS}|' ${WORKDIR}/multistrap.conf
    sed -i 's|##CONFIG_SCRIPT##|./tmp/work/${PF}/${DISTRO}/configscript.sh|' ${WORKDIR}/multistrap.conf
    sed -i 's|##SETUP_SCRIPT##|./tmp/work/${PF}/${DISTRO}/setup.sh|' ${WORKDIR}/multistrap.conf
    sed -i 's|##DIR_HOOKS##|./tmp/work/${PF}/${DISTRO}/hooks_multistrap|' ${WORKDIR}/multistrap.conf

    # Multistrap config use relative paths, so ensure that we are in the right folder
    cd ${TOPDIR}

    # Create root filesystem
    sudo multistrap -a ${DISTRO_ARCH} -d "${BUILDCHROOT_DIR}" -f "${WORKDIR}/multistrap.conf" || true

    # Install package builder script
    sudo install -m 755 ${FILESDIR}/build.sh ${BUILDCHROOT_DIR}

    # Configure root filesystem
    sudo chroot ${BUILDCHROOT_DIR} /configscript.sh
}
