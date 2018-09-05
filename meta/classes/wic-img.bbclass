# This software is a part of ISAR.
# Copyright (C) 2018 Siemens AG
#
# this class is heavily inspired by OEs ./meta/classes/image_types_wic.bbclass
#

python () {
    if not d.getVar('WKS_FILE', True):
        bb.fatal("WKS_FILE must be set")
}

ROOTFS_TYPE ?= "ext4"

STAGING_DATADIR ?= "/usr/lib/"
STAGING_LIBDIR ?= "/usr/lib/"
STAGING_DIR ?= "${TMPDIR}"
IMAGE_BASENAME ?= "${PN}-${DISTRO}"
FAKEROOTCMD ?= "${ISARROOT}/scripts/wic_fakeroot"
RECIPE_SYSROOT_NATIVE ?= "/"
BUILDCHROOT_DIR = "${BUILDCHROOT_TARGET_DIR}"

do_wic_image[stamp-extra-info] = "${DISTRO}-${MACHINE}"

WIC_CREATE_EXTRA_ARGS ?= ""

WICVARS += "\
           BBLAYERS IMGDEPLOYDIR DEPLOY_DIR_IMAGE FAKEROOTCMD IMAGE_BASENAME IMAGE_BOOT_FILES \
           IMAGE_LINK_NAME IMAGE_ROOTFS INITRAMFS_FSTYPES INITRD INITRD_LIVE ISODIR RECIPE_SYSROOT_NATIVE \
           ROOTFS_SIZE STAGING_DATADIR STAGING_DIR STAGING_LIBDIR TARGET_SYS TRANSLATED_TARGET_ARCH"

# Isar specific vars used in our plugins
WICVARS += "KERNEL_IMAGE INITRD_IMAGE DISTRO_ARCH"

python do_rootfs_wicenv () {
    wicvars = d.getVar('WICVARS', True)
    if not wicvars:
        return

    stdir = d.getVar('STAGING_DIR', True)
    outdir = os.path.join(stdir, d.getVar('MACHINE', True), 'imgdata')
    bb.utils.mkdirhier(outdir)
    basename = d.getVar('IMAGE_BASENAME', True)
    with open(os.path.join(outdir, basename) + '.env', 'w') as envf:
        for var in wicvars.split():
            value = d.getVar(var, True)
            if value:
                envf.write('%s="%s"\n' % (var, value.strip()))

    # this part is stolen from OE ./meta/recipes-core/meta/wic-tools.bb
    with open(os.path.join(outdir, "wic-tools.env"), 'w') as envf:
        for var in ('RECIPE_SYSROOT_NATIVE', 'STAGING_DATADIR', 'STAGING_LIBDIR'):
            envf.write('%s="%s"\n' % (var, d.getVar(var, True).strip()))

}

addtask do_rootfs_wicenv after do_copy_boot_files before do_wic_image
do_rootfs_wicenv[vardeps] += "${WICVARS}"
do_rootfs_wicenv[prefuncs] = 'set_image_size'

WIC_IMAGE_FILE ="${DEPLOY_DIR_IMAGE}/${PN}-${DISTRO}-${MACHINE}.wic.img"

do_build[stamp-extra-info] = "${DISTRO}-${DISTRO_ARCH}"

do_wic_image() {
    if ! grep -q ${BUILDCHROOT_DIR}/dev /proc/mounts; then
        sudo mount -t devtmpfs -o mode=0755,nosuid devtmpfs ${BUILDCHROOT_DIR}/dev
        sudo mount -t proc none ${BUILDCHROOT_DIR}/proc
    fi
    for dir in ${BBLAYERS} ${STAGING_DIR} ${ISARROOT}/scripts; do
	sudo mkdir -p ${BUILDCHROOT_DIR}/$dir
        sudo mount --bind $dir ${BUILDCHROOT_DIR}/$dir
    done
    export FAKEROOTCMD=${FAKEROOTCMD}
    export BUILDDIR=${BUILDDIR}
    export MTOOLS_SKIP_CHECK=1

    sudo -E chroot ${BUILDCHROOT_DIR} ${ISARROOT}/scripts/wic create ${WKS_FILE} --vars "${STAGING_DIR}/${MACHINE}/imgdata/" -o /tmp/ -e ${IMAGE_BASENAME} ${WIC_CREATE_EXTRA_ARGS}
    sudo chown -R $(stat -c "%U" ${ISARROOT}) ${ISARROOT}/meta ${ISARROOT}/meta-isar ${ISARROOT}/scripts
    cp -f `ls -t -1 ${BUILDCHROOT_DIR}/tmp/${WKS_FILE}*.direct | head -1` ${WIC_IMAGE_FILE}
}

do_wic_image[depends] = "buildchroot-target:do_build"

addtask wic_image before do_build after do_install_imager_deps
