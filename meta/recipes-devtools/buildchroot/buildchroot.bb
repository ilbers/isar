# Root filesystem for packages building
#
# This software is a part of ISAR.
# Copyright (C) 2015-2016 ilbers GmbH

DESCRIPTION = "Multistrap development filesystem"

LICENSE = "gpl-2.0"
LIC_FILES_CHKSUM = "file://${LAYERDIR_isar}/licenses/COPYING.GPLv2;md5=751419260aa954499f7abaabaa882bbe"

FILESPATH =. "${LAYERDIR_core}/recipes-devtools/buildchroot/files:"
SRC_URI = "file://multistrap.conf.in \
           file://configscript.sh \
           file://setup.sh \
           file://download_dev-random \
           file://build.sh"
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

WORKDIR = "${TMPDIR}/work/${DISTRO}-${DISTRO_ARCH}/${PN}"

do_build[stamp-extra-info] = "${DISTRO}-${DISTRO_ARCH}"
do_build[dirs] = "${WORKDIR}/hooks_multistrap"

do_build() {
    E="${@ bb.utils.export_proxies(d)}"

    chmod +x "${WORKDIR}/setup.sh"
    chmod +x "${WORKDIR}/configscript.sh"
    install -m 755 "${WORKDIR}/download_dev-random" "${WORKDIR}/hooks_multistrap/"

    # Multistrap accepts only relative path in configuration files, so get it:
    cd ${TOPDIR}
    WORKDIR_REL=${@ os.path.relpath(d.getVar("WORKDIR", True))}

    # Adjust multistrap config
    sed -e 's|##BUILDCHROOT_PREINSTALL##|${BUILDCHROOT_PREINSTALL}|g' \
        -e 's|##DISTRO_MULTICONF_BOOTSTRAP##|${DISTRO_MULTICONF_BOOTSTRAP}|g' \
        -e 's|##DISTRO_MULTICONF_APTSOURCES##|${DISTRO_MULTICONF_APTSOURCES}|g' \
        -e 's|##DISTRO_APT_SOURCE##|${DISTRO_APT_SOURCE}|g' \
        -e 's|##DISTRO_APT_SOURCE_SEC##|${DISTRO_APT_SOURCE_SEC}|g' \
        -e 's|##DISTRO_SUITE##|${DISTRO_SUITE}|g' \
        -e 's|##DISTRO_COMPONENTS##|${DISTRO_COMPONENTS}|g' \
        -e 's|##CONFIG_SCRIPT##|./'"$WORKDIR_REL"'/configscript.sh|g' \
        -e 's|##SETUP_SCRIPT##|./'"$WORKDIR_REL"'/setup.sh|g' \
        -e 's|##DIR_HOOKS##|./'"$WORKDIR_REL"'/hooks_multistrap|g' \
           "${WORKDIR}/multistrap.conf.in" > "${WORKDIR}/multistrap.conf"

    [ ! -d ${BUILDCHROOT_DIR}/proc ] && install -d -m 555 ${BUILDCHROOT_DIR}/proc
    sudo mount -t proc none ${BUILDCHROOT_DIR}/proc
    _do_build_cleanup() {
        ret=$?
        sudo umount ${BUILDCHROOT_DIR}/proc 2>/dev/null || true
        (exit $ret) || bb_exit_handler
    }
    trap '_do_build_cleanup' EXIT

    # Create root filesystem
    sudo -E multistrap -a ${DISTRO_ARCH} -d "${BUILDCHROOT_DIR}" -f "${WORKDIR}/multistrap.conf"

    # Install package builder script
    sudo install -m 755 ${WORKDIR}/build.sh ${BUILDCHROOT_DIR}

    # Configure root filesystem
    sudo chroot ${BUILDCHROOT_DIR} /configscript.sh
    _do_build_cleanup
}
