# This software is a part of ISAR.
# Copyright (c) Siemens AG, 2019

# Features of the rootfs creation:
# available features are:
# 'finalize-rootfs' - delete files needed to chroot into the rootfs
ROOTFS_FEATURES ?= ""

ROOTFS_POSTPROCESS_COMMAND += "${@bb.utils.contains('ROOTFS_FEATURES', 'finalize-rootfs', 'rootfs_postprocess_finalize', '', d)}"
rootfs_postprocess_finalize() {
    sudo -s <<'EOSUDO'
        test ! -e "${ROOTFSDIR}/usr/share/doc/qemu-user-static" && \
            find "${ROOTFSDIR}/usr/bin" \
                -maxdepth 1 -name 'qemu-*-static' -type f -delete

        mountpoint -q '${ROOTFSDIR}/isar-apt' && \
            umount -l ${ROOTFSDIR}/isar-apt
        rmdir --ignore-fail-on-non-empty ${ROOTFSDIR}/isar-apt

        mountpoint -q '${ROOTFSDIR}/base-apt' && \
            umount -l ${ROOTFSDIR}/base-apt
        rmdir --ignore-fail-on-non-empty ${ROOTFSDIR}/base-apt

        mountpoint -q '${ROOTFSDIR}/dev' && \
            umount -l ${ROOTFSDIR}/dev
        mountpoint -q '${ROOTFSDIR}/sys' && \
            umount -l ${ROOTFSDIR}/proc
        mountpoint -q '${ROOTFSDIR}/sys' && \
            umount -l ${ROOTFSDIR}/sys

        rm -f "${ROOTFSDIR}/etc/apt/apt.conf.d/55isar-fallback.conf"

        rm -f "${ROOTFSDIR}/etc/apt/sources.list.d/isar-apt.list"
        rm -f "${ROOTFSDIR}/etc/apt/sources.list.d/base-apt.list"

        mv "${ROOTFSDIR}/etc/apt/sources-list" \
            "${ROOTFSDIR}/etc/apt/sources.list.d/bootstrap.list"

        rm -f "${ROOTFSDIR}/etc/apt/sources-list"
EOSUDO
}

do_rootfs_postprocess[vardeps] = "${ROOTFS_POSTPROCESS_COMMAND}"
python do_rootfs_postprocess() {
    cmds = d.getVar("ROOTFS_POSTPROCESS_COMMAND")
    if cmds is None or not cmds.strip():
        return
    cmds = cmds.split()
    for cmd in cmds:
        bb.build.exec_func(cmd, d)
}
addtask rootfs_postprocess before do_rootfs after do_rootfs_install

python do_rootfs() {
    """Virtual task"""
    pass
}
addtask rootfs before do_build
