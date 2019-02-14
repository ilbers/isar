# This software is a part of ISAR.
# Copyright (C) 2018 Siemens AG
#
# this class is heavily inspired by OEs ./meta/classes/image_types_wic.bbclass
#

WKS_FILE_CHECKSUM = "${@'${WKS_FULL_PATH}:%s' % os.path.exists('${WKS_FULL_PATH}')}"

python do_write_wks_template () {
    """Write out expanded template contents to WKS_FULL_PATH."""
    import re

    template_body = d.getVar('_WKS_TEMPLATE')

    # Remove any remnant variable references left behind by the expansion
    # due to undefined variables
    expand_var_regexp = re.compile(r"\${[^{}@\n\t :]+}")
    while True:
        new_body = re.sub(expand_var_regexp, '', template_body)
        if new_body == template_body:
            break
        else:
            template_body = new_body

    wks_file = d.getVar('WKS_FULL_PATH')
    with open(wks_file, 'w') as f:
        f.write(template_body)
}

python () {
    wks_full_path = None

    wks_file = d.getVar('WKS_FILE', True)
    if not wks_file:
        bb.fatal("WKS_FILE must be set")
    if not wks_file.endswith('.wks') and not wks_file.endswith('.wks.in'):
        wks_file += '.wks'

    if os.path.isabs(wks_file):
        if os.path.exists(wks_file):
            wks_full_path = wks_file
    else:
        bbpaths = d.getVar('BBPATH', True).split(':')
        corebase = d.getVar('COREBASE', True)
        search_path = ':'.join('%s/wic' % p for p in bbpaths) + ':' + \
            ':'.join('%s/scripts/lib/wic/canned-wks' % l \
                     for l in (bbpaths + [corebase]))
        wks_full_path = bb.utils.which(search_path, wks_file)

    if not wks_full_path:
        bb.fatal("WKS_FILE '%s' not found" % wks_file)

    d.setVar('WKS_FULL_PATH', wks_full_path)

    wks_file_u = wks_full_path
    wks_file = wks_full_path
    base, ext = os.path.splitext(wks_file)
    if ext == '.in' and os.path.exists(wks_file):
        wks_out_file = os.path.join(d.getVar('WORKDIR'), os.path.basename(base))
        d.setVar('WKS_FULL_PATH', wks_out_file)
        d.setVar('WKS_TEMPLATE_PATH', wks_file_u)
        d.setVar('WKS_FILE_CHECKSUM', '${WKS_TEMPLATE_PATH}:True')

        # We need to re-parse each time the file changes, and bitbake
        # needs to be told about that explicitly.
        bb.parse.mark_dependency(d, wks_file)

        try:
            with open(wks_file, 'r') as f:
                body = f.read()
        except (IOError, OSError) as exc:
            pass
        else:
            # Previously, I used expandWithRefs to get the dependency list
            # and add it to WICVARS, but there's no point re-parsing the
            # file in process_wks_template as well, so just put it in
            # a variable and let the metadata deal with the deps.
            d.setVar('_WKS_TEMPLATE', body)
            bb.build.addtask('do_write_wks_template', 'do_wic_image', None, d)
}

inherit buildchroot

# wic comes with reasonable defaults, and the proper interface is the wks file
ROOTFS_EXTRA ?= "0"

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

WIC_IMAGE_FILE ="${DEPLOY_DIR_IMAGE}/${IMAGE_FULLNAME}.wic.img"

do_build[stamp-extra-info] = "${DISTRO}-${DISTRO_ARCH}"

do_wic_image() {
    buildchroot_do_mounts
    sudo -s <<'EOSUDO'
        ( flock 9
        for dir in ${BBLAYERS} ${STAGING_DIR} ${ISARROOT}/scripts; do
            mkdir -p ${BUILDCHROOT_DIR}/$dir
            if ! mountpoint ${BUILDCHROOT_DIR}/$dir >/dev/null 2>&1; then
                mount --bind --make-private $dir ${BUILDCHROOT_DIR}/$dir
            fi
        done
        ) 9>${MOUNT_LOCKFILE}
EOSUDO
    export FAKEROOTCMD=${FAKEROOTCMD}
    export BUILDDIR=${BUILDDIR}
    export MTOOLS_SKIP_CHECK=1

    sudo -E chroot ${BUILDCHROOT_DIR} \
        ${ISARROOT}/scripts/wic create ${WKS_FULL_PATH} \
            --vars "${STAGING_DIR}/${MACHINE}/imgdata/" \
            -o /tmp/${IMAGE_FULLNAME}.wic/ \
            -e ${IMAGE_BASENAME} ${WIC_CREATE_EXTRA_ARGS}
    sudo chown -R $(stat -c "%U" ${ISARROOT}) ${ISARROOT}/meta ${ISARROOT}/meta-isar ${ISARROOT}/scripts || true
    cp -f $(ls -t -1 ${BUILDCHROOT_DIR}/tmp/${IMAGE_FULLNAME}.wic/*.direct | head -1) ${WIC_IMAGE_FILE}
}

do_wic_image[file-checksums] += "${WKS_FILE_CHECKSUM}"
do_wic_image[depends] = "buildchroot-target:do_build"

addtask wic_image before do_build after do_install_imager_deps
