# Root filesystem for target installation
#
# This software is a part of ISAR.
# Copyright (C) 2015-2018 ilbers GmbH

inherit image
inherit isar-bootstrap-helper

FILESPATH =. "${LAYERDIR_isar}/conf/distro:"
SRC_URI += "${@ 'file://${DISTRO_CONFIG_SCRIPT}' if '${DISTRO_CONFIG_SCRIPT}' else '' }"

DEPENDS += "${IMAGE_INSTALL} ${IMAGE_TRANSIENT_PACKAGES}"

IMAGE_TRANSIENT_PACKAGES += "isar-cfg-localepurge"

WORKDIR = "${TMPDIR}/work/${DISTRO}-${DISTRO_ARCH}/${PN}"

ISAR_RELEASE_CMD_DEFAULT = "git -C ${LAYERDIR_isar} describe --tags --dirty --match 'v[0-9].[0-9]*'"
ISAR_RELEASE_CMD ?= "${ISAR_RELEASE_CMD_DEFAULT}"

do_rootfs[root_cleandirs] = "${IMAGE_ROOTFS} \
                             ${IMAGE_ROOTFS}/isar-apt"

isar_image_gen_fstab() {
    cat > ${WORKDIR}/fstab << EOF
# Begin /etc/fstab
/dev/root	/		auto		defaults		0	0
proc		/proc		proc		nosuid,noexec,nodev	0	0
sysfs		/sys		sysfs		nosuid,noexec,nodev	0	0
devpts		/dev/pts	devpts		gid=5,mode=620		0	0
tmpfs		/run		tmpfs		defaults		0	0
devtmpfs	/dev		devtmpfs	mode=0755,nosuid	0	0

# End /etc/fstab
EOF
}

isar_image_gen_rootfs() {
    setup_root_file_system --clean --keep-apt-cache \
        --fstab "${WORKDIR}/fstab" \
        "${IMAGE_ROOTFS}" ${IMAGE_PREINSTALL} ${IMAGE_INSTALL}
}

isar_image_conf_rootfs() {
    # Configure root filesystem
    if [ -n "${DISTRO_CONFIG_SCRIPT}" ]; then
        sudo install -m 755 "${WORKDIR}/${DISTRO_CONFIG_SCRIPT}" "${IMAGE_ROOTFS}"
        sudo chroot ${IMAGE_ROOTFS} /${DISTRO_CONFIG_SCRIPT} "${MACHINE_SERIAL}" \
                                                             "${BAUDRATE_TTY}"
        sudo rm "${IMAGE_ROOTFS}/${DISTRO_CONFIG_SCRIPT}"
   fi
}

isar_image_cleanup() {
    # Cleanup
    sudo rm "${IMAGE_ROOTFS}/etc/apt/sources.list.d/isar-apt.list"
    test ! -e "${IMAGE_ROOTFS}/usr/share/doc/qemu-user-static" && \
         sudo find "${IMAGE_ROOTFS}/usr/bin" \
              -maxdepth 1 -name 'qemu-*-static' -type f -delete
    sudo umount -l ${IMAGE_ROOTFS}/isar-apt
    sudo rmdir ${IMAGE_ROOTFS}/isar-apt
    sudo umount -R -l ${IMAGE_ROOTFS}/dev
    sudo umount -l ${IMAGE_ROOTFS}/proc
    sudo umount -R -l ${IMAGE_ROOTFS}/sys
    sudo rm -f "${IMAGE_ROOTFS}/etc/apt/apt.conf.d/55isar-fallback.conf"
}

python do_rootfs() {
    bb.build.exec_func("isar_image_gen_fstab", d)
    bb.build.exec_func("isar_image_gen_rootfs", d)
    bb.build.exec_func("isar_image_conf_rootfs", d)
    bb.build.exec_func("isar_image_cleanup", d)
}
