# This software is a part of ISAR.
# Copyright (C) 2018 Siemens AG
#
# this class is heavily inspired by OEs ./meta/classes/image_types_wic.bbclass
#

USING_WIC = "${@bb.utils.contains('IMAGE_BASETYPES', 'wic', '1', '0', d)}"
WKS_FILE_CHECKSUM = "${@'${WKS_FULL_PATH}:%s' % os.path.exists('${WKS_FULL_PATH}') if bb.utils.to_boolean(d.getVar('USING_WIC')) else ''}"

WKS_FILE ??= "sdimage-efi"

do_copy_wks_template[file-checksums] += "${WKS_FILE_CHECKSUM}"
do_copy_wks_template[vardepsexclude] += "WKS_TEMPLATE_PATH"
do_copy_wks_template () {
    cp -f '${WKS_TEMPLATE_PATH}' '${WORKDIR}/${WKS_TEMPLATE_FILE}'
}

python () {
    if not bb.utils.to_boolean(d.getVar('USING_WIC')):
        return

    if d.getVar('WIC_IMAGER_INSTALL'):
        bb.warn("WIC_IMAGER_INSTALL is deprecated, use IMAGER_INSTALL:wic instead")

    import itertools
    import re

    wks_full_path = None

    wks_file = d.getVar('WKS_FILE')
    if not wks_file:
        bb.fatal("WKS_FILE must be set")
    if not wks_file.endswith('.wks') and not wks_file.endswith('.wks.in'):
        wks_file += '.wks'

    if os.path.isabs(wks_file):
        if os.path.exists(wks_file):
            wks_full_path = wks_file
    else:
        bbpaths = d.getVar('BBPATH').split(':')
        corebase_paths = bbpaths

        corebase = d.getVar('COREBASE')
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

IMAGER_INSTALL:wic += "${@d.getVar('WIC_IMAGER_INSTALL') or ''}"
# wic comes with reasonable defaults, and the proper interface is the wks file
ROOTFS_EXTRA ?= "0"

STAGING_DATADIR ?= "/usr/lib/"
STAGING_LIBDIR ?= "/usr/lib/"
STAGING_DIR ?= "${TMPDIR}"
IMAGE_BASENAME ?= "${PN}-${DISTRO}"
FAKEROOTCMD ?= "${SCRIPTSDIR}/wic_fakeroot"
RECIPE_SYSROOT_NATIVE ?= "/"

WIC_CREATE_EXTRA_ARGS ?= ""
WIC_DEPLOY_PARTITIONS ?= "0"

# taken from OE, do not touch directly
WICVARS += "\
           BBLAYERS IMGDEPLOYDIR DEPLOY_DIR_IMAGE FAKEROOTCMD IMAGE_BASENAME IMAGE_BOOT_FILES IMAGE_EFI_BOOT_FILES \
           IMAGE_LINK_NAME IMAGE_ROOTFS INITRAMFS_FSTYPES INITRD INITRD_LIVE ISODIR RECIPE_SYSROOT_NATIVE \
           ROOTFS_SIZE STAGING_DATADIR STAGING_DIR STAGING_LIBDIR TARGET_SYS TRANSLATED_TARGET_ARCH"

# Isar specific vars used in our plugins
WICVARS += "DISTRO DISTRO_ARCH KERNEL_FILE"

python do_rootfs_wicenv () {
    wicvars = d.getVar('WICVARS')
    if not wicvars:
        return

    stdir = d.getVar('STAGING_DIR')
    outdir = os.path.join(stdir, d.getVar('MACHINE'), 'imgdata')
    bb.utils.mkdirhier(outdir)
    basename = d.getVar('IMAGE_BASENAME')
    with open(os.path.join(outdir, basename) + '.env', 'w') as envf:
        for var in wicvars.split():
            value = d.getVar(var)
            if value:
                envf.write('{}="{}"\n'.format(var, value.strip()))

    # this part is stolen from OE ./meta/recipes-core/meta/wic-tools.bb
    with open(os.path.join(outdir, "wic-tools.env"), 'w') as envf:
        for var in ('RECIPE_SYSROOT_NATIVE', 'STAGING_DATADIR', 'STAGING_LIBDIR'):
            envf.write('{}="{}"\n'.format(var, d.getVar(var).strip()))

}

addtask do_rootfs_wicenv after do_rootfs before do_image_wic
do_rootfs_wicenv[vardeps] += "${WICVARS}"
do_rootfs_wicenv[prefuncs] = 'set_image_size'
do_rootfs_wicenv[network] = "${TASK_USE_SUDO}"

check_for_wic_warnings() {
    WARN="$(grep -e '^WARNING' ${T}/log.do_image_wic || true)"
    if [ -n "$WARN" ]; then
        bbwarn "$WARN"
    fi
}

do_image_wic[file-checksums] += "${WKS_FILE_CHECKSUM}"
IMAGE_CMD:wic() {
    generate_wic_image
    check_for_wic_warnings
}

SCHROOT_MOUNTS += "${BBLAYERS} ${STAGING_DIR} ${SCRIPTSDIR} ${BITBAKEDIR}"
SCHROOT_MOUNTS[vardepsexclude] += "BITBAKEDIR"

generate_wic_image[vardepsexclude] += "WKS_FULL_PATH BITBAKEDIR TOPDIR"
generate_wic_image() {
    export FAKEROOTCMD=${FAKEROOTCMD}
    export BUILDDIR=${TOPDIR}
    export MTOOLS_SKIP_CHECK=1
    export PYTHONDONTWRITEBYTECODE=1
    mkdir -p ${IMAGE_ROOTFS}/../pseudo
    touch ${IMAGE_ROOTFS}/../pseudo/files.db

    imager_run -p -d ${PP_WORK} -u root <<'EOIMAGER'
        set -e

        # The python path is hard-coded as /usr/bin/python3-native/python3 in wic. Handle that.
        mkdir -p /usr/bin/python3-native/
        if [ $(head -1 $(which bmaptool) | grep python3) ];then
            ln -fs /usr/bin/python3 /usr/bin/python3-native/python3
        else
            ln -fs /usr/bin/python2 /usr/bin/python3-native/python3
        fi

        export PATH="${BITBAKEDIR}/bin:$PATH"

        "${SCRIPTSDIR}"/wic create "${WKS_FULL_PATH}" \
            --vars "${STAGING_DIR}/${MACHINE}/imgdata/" \
            -o "/tmp/${IMAGE_FULLNAME}.wic/" \
            --bmap \
            -e "${IMAGE_BASENAME}" ${WIC_CREATE_EXTRA_ARGS}

        WIC_DIRECT=$(ls -t -1 /tmp/${IMAGE_FULLNAME}.wic/*.direct | head -1)
        mv -f ${WIC_DIRECT} ${PP_DEPLOY}/${IMAGE_FULLNAME}.wic
        mv -f ${WIC_DIRECT}.bmap ${PP_DEPLOY}/${IMAGE_FULLNAME}.wic.bmap
        # deploy partition files if requested (ending with .p<x>)
        if [ "${WIC_DEPLOY_PARTITIONS}" -eq "1" ]; then
            # locate *.direct.p<x> partition files
            find "/tmp/${IMAGE_FULLNAME}.wic/" -type f -regextype sed -regex ".*\.direct.*\.p[0-9]\{1,\}" | while read f; do
                suffix=$(basename $f | sed 's/.*\.direct\(.*\)/\1/')
                mv -f ${f} ${PP_DEPLOY}/${IMAGE_FULLNAME}.wic${suffix}
            done
        fi
EOIMAGER

    sudo chown -R $(stat -c "%U" ${LAYERDIR_core}) ${LAYERDIR_core} ${LAYERDIR_isar} ${SCRIPTSDIR} || true
    sudo chown -R $(id -u):$(id -g) "${DEPLOY_DIR_IMAGE}/${IMAGE_FULLNAME}.wic"*
    rm -rf ${IMAGE_ROOTFS}/../pseudo

    cat ${DEPLOY_DIR_IMAGE}/${IMAGE_FULLNAME}.manifest \
        ${DEPLOY_DIR_IMAGE}/${INITRD_DEPLOY_FILE}.manifest \
        ${WORKDIR}/imager.manifest 2>/dev/null \
        | sort | uniq > "${DEPLOY_DIR_IMAGE}/${IMAGE_FULLNAME}.wic.manifest"

    if ${@bb.utils.contains('ROOTFS_FEATURES', 'generate-sbom', 'true', 'false', d)} ; then
        for bomtype in ${SBOM_TYPES}; do
            merge_wic_sbom $bomtype
        done
    fi
}

merge_wic_sbom() {
    BOMTYPE="$1"
    TIMESTAMP=$(date --iso-8601=s -d @${SOURCE_DATE_EPOCH})
    sbom_document_uuid="${@d.getVar('SBOM_DOCUMENT_UUID') or generate_document_uuid(d, False)}"

    cat ${DEPLOY_DIR_IMAGE}/${IMAGE_FULLNAME}.${bomtype}.json \
        ${DEPLOY_DIR_IMAGE}/${INITRD_DEPLOY_FILE}.${bomtype}.json \
        ${WORKDIR}/imager.${bomtype}.json 2>/dev/null | \
    bwrap \
        --unshare-user \
        --unshare-pid \
        --bind ${SBOM_CHROOT} / \
        -- debsbom -v merge -t $BOMTYPE \
            --distro-name '${SBOM_DISTRO_NAME}-Image' --distro-supplier '${SBOM_DISTRO_SUPPLIER}' \
            --distro-version '${SBOM_DISTRO_VERSION}' --base-distro-vendor '${SBOM_BASE_DISTRO_VENDOR}' \
            --cdx-serialnumber $sbom_document_uuid \
            --spdx-namespace '${SBOM_SPDX_NAMESPACE_PREFIX}'-$sbom_document_uuid \
            --timestamp $TIMESTAMP - -o - \
     > ${DEPLOY_DIR_IMAGE}/${IMAGE_FULLNAME}.wic.$bomtype.json
}
