# This software is a part of ISAR.
# Copyright (C) 2018 Siemens AG
#
# this class is heavily inspired by OEs ./meta/classes/image_types_wic.bbclass
#

USING_WIC = "${@bb.utils.contains('IMAGE_BASETYPES', 'wic', '1', '0', d)}"
WKS_FILE_CHECKSUM = "${@'${WKS_FULL_PATH}:%s' % os.path.exists('${WKS_FULL_PATH}') if d.getVar('USING_WIC') == '1' else ''}"

WKS_FILE ??= "sdimage-efi"

do_copy_wks_template[file-checksums] += "${WKS_FILE_CHECKSUM}"
do_copy_wks_template[vardepsexclude] += "WKS_TEMPLATE_PATH"
do_copy_wks_template () {
    cp -f '${WKS_TEMPLATE_PATH}' '${WORKDIR}/${WKS_TEMPLATE_FILE}'
}

python () {
    if not d.getVar('USING_WIC') == '1':
        return

    import itertools
    import re

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
        corebase_paths = bbpaths

        corebase = d.getVar('COREBASE', True)
        if corebase is not None:
            corebase_paths.append(corebase)

        search_path = ":".join(itertools.chain(
            (p + "/wic" for p in bbpaths),
            (l + "/scripts/lib/wic/canned-wks"
             for l in (corebase_paths)),
        ))
        wks_full_path = bb.utils.which(search_path, wks_file)

    if not wks_full_path:
        bb.fatal("WKS_FILE '{}' not found".format(wks_file))

    d.setVar('WKS_FULL_PATH', wks_full_path)

    wks_file_u = wks_full_path
    wks_file = wks_full_path
    base, ext = os.path.splitext(wks_file)
    if ext == '.in' and os.path.exists(wks_file):
        wks_out_file = os.path.join(d.getVar('WORKDIR'), os.path.basename(base))
        d.setVar('WKS_FULL_PATH', wks_out_file)
        d.setVar('WKS_TEMPLATE_PATH', wks_file_u)
        d.setVar('WKS_FILE_CHECKSUM', '${WKS_TEMPLATE_PATH}:True')

        wks_template_file = os.path.basename(base) + '.tmpl'
        d.setVar('WKS_TEMPLATE_FILE', wks_template_file)
        d.appendVar('TEMPLATE_FILES', " {}".format(wks_template_file))

        # We need to re-parse each time the file changes, and bitbake
        # needs to be told about that explicitly.
        bb.parse.mark_dependency(d, wks_file)

        expand_var_regexp = re.compile(r"\${(?P<name>[^{}@\n\t :]+)}")

        try:
            with open(wks_file, 'r') as f:
                d.appendVar("TEMPLATE_VARS", " {}".format(
                    " ".join(expand_var_regexp.findall(f.read()))))
        except (IOError, OSError) as exc:
            pass
        else:
            bb.build.addtask('do_copy_wks_template', 'do_transform_template do_image_wic', None, d)
            bb.build.addtask('do_transform_template', 'do_image_wic', None, d)
}

inherit buildchroot

IMAGER_INSTALL_wic += "${WIC_IMAGER_INSTALL}"
# wic comes with reasonable defaults, and the proper interface is the wks file
ROOTFS_EXTRA ?= "0"

STAGING_DATADIR ?= "/usr/lib/"
STAGING_LIBDIR ?= "/usr/lib/"
STAGING_DIR ?= "${TMPDIR}"
IMAGE_BASENAME ?= "${PN}-${DISTRO}"
FAKEROOTCMD ?= "${SCRIPTSDIR}/wic_fakeroot"
RECIPE_SYSROOT_NATIVE ?= "/"
BUILDCHROOT_DIR = "${BUILDCHROOT_TARGET_DIR}"

WIC_CREATE_EXTRA_ARGS ?= ""
WIC_DEPLOY_PARTITIONS ?= "0"

# taken from OE, do not touch directly
WICVARS += "\
           BBLAYERS IMGDEPLOYDIR DEPLOY_DIR_IMAGE FAKEROOTCMD IMAGE_BASENAME IMAGE_BOOT_FILES \
           IMAGE_LINK_NAME IMAGE_ROOTFS INITRAMFS_FSTYPES INITRD INITRD_LIVE ISODIR RECIPE_SYSROOT_NATIVE \
           ROOTFS_SIZE STAGING_DATADIR STAGING_DIR STAGING_LIBDIR TARGET_SYS TRANSLATED_TARGET_ARCH"

# Isar specific vars used in our plugins
WICVARS += "DISTRO DISTRO_ARCH"

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
                envf.write('{}="{}"\n'.format(var, value.strip()))

    # this part is stolen from OE ./meta/recipes-core/meta/wic-tools.bb
    with open(os.path.join(outdir, "wic-tools.env"), 'w') as envf:
        for var in ('RECIPE_SYSROOT_NATIVE', 'STAGING_DATADIR', 'STAGING_LIBDIR'):
            envf.write('{}="{}"\n'.format(var, d.getVar(var, True).strip()))

}

addtask do_rootfs_wicenv after do_rootfs before do_image_wic
do_rootfs_wicenv[vardeps] += "${WICVARS}"
do_rootfs_wicenv[prefuncs] = 'set_image_size'

check_for_wic_warnings() {
    WARN="$(grep -e '^WARNING' ${T}/log.do_image_wic || true)"
    if [ -n "$WARN" ]; then
        bbwarn "$WARN"
    fi
}

do_image_wic[file-checksums] += "${WKS_FILE_CHECKSUM}"
IMAGE_CMD_wic() {
    wic_do_mounts
    generate_wic_image
    check_for_wic_warnings
}

wic_do_mounts[vardepsexclude] += "BITBAKEDIR"
wic_do_mounts() {
    buildchroot_do_mounts
    sudo -s <<'EOSUDO'
        ( flock 9
        set -e
        for dir in ${BBLAYERS} ${STAGING_DIR} ${SCRIPTSDIR} ${BITBAKEDIR}; do
            mkdir -p ${BUILDCHROOT_DIR}/$dir
            if ! mountpoint ${BUILDCHROOT_DIR}/$dir >/dev/null 2>&1; then
                mount --bind --make-private $dir ${BUILDCHROOT_DIR}/$dir
            fi
        done
        ) 9>${MOUNT_LOCKFILE}
EOSUDO
}

generate_wic_image[vardepsexclude] += "WKS_FULL_PATH BITBAKEDIR TOPDIR"
generate_wic_image() {
    export FAKEROOTCMD=${FAKEROOTCMD}
    export BUILDDIR=${TOPDIR}
    export MTOOLS_SKIP_CHECK=1
    mkdir -p ${IMAGE_ROOTFS}/../pseudo
    touch ${IMAGE_ROOTFS}/../pseudo/files.db

    # create the temp dir in the buildchroot to ensure uniqueness
    WICTMP=$(cd ${BUILDCHROOT_DIR}; mktemp -d -p tmp)

    sudo -E chroot ${BUILDCHROOT_DIR} \
        sh -c ' \
          BITBAKEDIR="$1"
          SCRIPTSDIR="$2"
          WKS_FULL_PATH="$3"
          STAGING_DIR="$4"
          MACHINE="$5"
          WICTMP="$6"
          IMAGE_FULLNAME="$7"
          IMAGE_BASENAME="$8"
          shift 8
          # The python path is hard-coded as /usr/bin/python3-native/python3 in wic. Handle that.
          mkdir -p /usr/bin/python3-native/
          if [ $(head -1 $(which bmaptool) | grep python3) ];then
            ln -fs /usr/bin/python3 /usr/bin/python3-native/python3
          else
            ln -fs /usr/bin/python2 /usr/bin/python3-native/python3
          fi
          export PATH="$BITBAKEDIR/bin:$PATH"
          "$SCRIPTSDIR"/wic create "$WKS_FULL_PATH" \
            --vars "$STAGING_DIR/$MACHINE/imgdata/" \
            -o "/$WICTMP/${IMAGE_FULLNAME}.wic/" \
            --bmap \
            -e "$IMAGE_BASENAME" $@' \
              my_script "${BITBAKEDIR}" "${SCRIPTSDIR}" "${WKS_FULL_PATH}" "${STAGING_DIR}" \
              "${MACHINE}" "${WICTMP}" "${IMAGE_FULLNAME}" "${IMAGE_BASENAME}" \
              ${WIC_CREATE_EXTRA_ARGS}

    sudo chown -R $(stat -c "%U" ${LAYERDIR_core}) ${LAYERDIR_core} ${LAYERDIR_isar} ${SCRIPTSDIR} || true
    WIC_DIRECT=$(ls -t -1 ${BUILDCHROOT_DIR}/$WICTMP/${IMAGE_FULLNAME}.wic/*.direct | head -1)
    sudo chown -R $(id -u):$(id -g) ${BUILDCHROOT_DIR}/${WICTMP}
    mv -f ${WIC_DIRECT} ${DEPLOY_DIR_IMAGE}/${IMAGE_FULLNAME}.wic
    mv -f ${WIC_DIRECT}.bmap ${DEPLOY_DIR_IMAGE}/${IMAGE_FULLNAME}.bmap
    # deploy partition files if requested (ending with .p<x>)
    if [ "${WIC_DEPLOY_PARTITIONS}" -eq "1" ]; then
        # locate *.direct.p<x> partition files
        find ${BUILDCHROOT_DIR}/${WICTMP} -type f -regextype sed -regex ".*\.direct.*\.p[0-9]\{1,\}" | while read f; do
            suffix=$(basename $f | sed 's/.*\.direct\(.*\)/\1/')
            mv -f ${f} ${DEPLOY_DIR_IMAGE}/${IMAGE_FULLNAME}.wic${suffix}
        done
    fi
    rm -rf ${BUILDCHROOT_DIR}/${WICTMP}
    rm -rf ${IMAGE_ROOTFS}/../pseudo
}
