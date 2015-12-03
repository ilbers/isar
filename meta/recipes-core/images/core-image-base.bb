# Multistrap Root Filesystem Creation
#
# Copyright (C) 2015-2016 ilbers GmbH

inherit zynq-image

DESCRIPTION = "Multistrap Root Filesystem"

LICENSE = "gpl-2.0"
LIC_FILES_CHKSUM = "file://LICENSE;md5=b234ee4d69f5fce4486a80fdaf4a4263"

SRC_URI = "\
    file://hooks/completion_chroot.sh \
    file://multistrap.conf            \
    file://setup.sh                   \
    file://configscript.sh            \
    file://LICENSE                    \
"

DEPENDS += "hello"
PV = "1.0"

S = "${WORKDIR}"

do_rootfs() {
    # Copy config files
    install -d ${WORKDIR}/rootfs
    install -d ${WORKDIR}/hooks
    install -m 644 ${THISDIR}/${PN}/multistrap.conf ${WORKDIR}
    install -m 755 ${THISDIR}/${PN}/setup.sh ${WORKDIR}
    install -m 755 ${THISDIR}/${PN}/configscript.sh ${WORKDIR}
    install -m 755  ${THISDIR}/${PN}/hooks/* ${WORKDIR}/hooks

    # If volume is mounted
    if mount |grep rootfs; then
        sudo umount ${WORKDIR}/rootfs
    fi

    # Create ext4 img
    dd if=/dev/zero of=${WORKDIR}/deb_rootfs.ext4 bs=1M count=800
    /sbin/mkfs.ext4 -F ${WORKDIR}/deb_rootfs.ext4
    sudo mount -o loop,rw ${WORKDIR}/deb_rootfs.ext4 ${WORKDIR}/rootfs

    # Create rootfs
    sudo multistrap -a armhf -d "${WORKDIR}/rootfs" -f "${WORKDIR}/multistrap.conf"

    # TODO: Integrate Debian package building
    sudo install ${WORKDIR}/../devroot/deploy/* ${WORKDIR}/rootfs/usr/local/bin

    # Stash away stuff for qemu
    mkdir -p ${BUILDDIR}/tmp/deploy/images
    # The shell doesn't seem to support braces
    cp ${WORKDIR}/rootfs/boot/vmlinuz* \
        ${WORKDIR}/rootfs/boot/initrd.img* \
        ${WORKDIR}/rootfs/usr/lib/linux-image*/vexpress*ca9*.dtb \
        ${WORKDIR}/rootfs/usr/lib/linux-image*/vexpress*ca15*.dtb \
        ${BUILDDIR}/tmp/deploy/images

    sudo umount ${WORKDIR}/rootfs
}

addtask image before do_build
addtask rootfs before do_image
addtask populate before do_rootfs

do_populate() {
    echo "Populate 3-rd party packets in deploy directory"
}

do_build[deptask] = "do_build"
do_populate[deptask] = "do_install"
