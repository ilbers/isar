# This software is a part of ISAR.
# Copyright (C) 2015-2017 ilbers GmbH

# Make workdir and stamps machine-specific without changing common PN target
WORKDIR = "${TMPDIR}/work/${DISTRO}-${DISTRO_ARCH}/${PN}-${MACHINE}/${PV}-${PR}"
DEPLOYDIR = "${WORKDIR}/deploy"
STAMP = "${STAMPS_DIR}/${DISTRO}-${DISTRO_ARCH}/${PN}-${MACHINE}/${PV}-${PR}"
STAMPCLEAN = "${STAMPS_DIR}/${DISTRO}-${DISTRO_ARCH}/${PN}-${MACHINE}/*-*"

# Sstate also needs to be machine-specific
SSTATE_MANIFESTS = "${TMPDIR}/sstate-control/${MACHINE}-${DISTRO}-${DISTRO_ARCH}"
SSTATETASKS += "do_copy_boot_files"

IMAGE_INSTALL ?= ""
IMAGE_FSTYPES ?= "ext4"
IMAGE_ROOTFS ?= "${WORKDIR}/rootfs"

KERNEL_IMAGE_PKG ??= "${@ ("linux-image-" + d.getVar("KERNEL_NAME")) if d.getVar("KERNEL_NAME") else ""}"
IMAGE_INSTALL += "${KERNEL_IMAGE_PKG}"

# Name of the image including distro&machine names
IMAGE_FULLNAME = "${PN}-${DISTRO}-${MACHINE}"

# These variables are used by wic and start_vm
KERNEL_IMAGE ?= "${IMAGE_FULLNAME}-${KERNEL_FILE}"
INITRD_IMAGE ?= ""
INITRD_DEPLOY_FILE = "${@ d.getVar('INITRD_IMAGE') or '${IMAGE_FULLNAME}-initrd.img'}"

# This defines the deployed dtbs for reuse by imagers
DTB_FILES ?= ""

# Useful variables for imager implementations:
PP = "/home/builder/${PN}-${MACHINE}"
PP_DEPLOY = "${PP}/deploy"
PP_ROOTFS = "${PP}/rootfs"
PP_WORK = "${PP}/work"

python(){
    # Debian Sid-Ports stores deb and deb-src in separate repos, which fails
    # sometimes on fetching sources if repos are not in sync during packages
    # version update. It makes Isar to fail on cache-deb-src, so disable it.
    base_repo_features = d.getVar('BASE_REPO_FEATURES') or ""
    feature_list = base_repo_features.split()
    if ('cache-deb-src' in feature_list):
        if (d.getVar('DISTRO') == 'debian-sid-ports'):
            bb.warn("cache-deb-src for debian-sid-ports is not supported, disabling")
            feature_list.remove("cache-deb-src")
            d.setVar('BASE_REPO_FEATURES', ' '.join(feature_list))
}

def cfg_script(d):
    cf = d.getVar('DISTRO_CONFIG_SCRIPT') or ''
    if cf:
        return 'file://' + cf
    return ''

FILESPATH =. "${LAYERDIR_core}/conf/distro:"
SRC_URI += "${@ cfg_script(d) }"

DEPENDS += "${IMAGE_INSTALL}"

ISAR_RELEASE_CMD_DEFAULT = "git -C ${LAYERDIR_core} describe --tags --dirty --match 'v[0-9].[0-9]*'"
ISAR_RELEASE_CMD ?= "${ISAR_RELEASE_CMD_DEFAULT}"

inherit multiarch
inherit essential

ROOTFSDIR = "${IMAGE_ROOTFS}"
ROOTFS_FEATURES += "clean-package-cache clean-pycache generate-manifest export-dpkg-status clean-log-files clean-debconf-cache"
ROOTFS_PACKAGES += "${IMAGE_PREINSTALL} ${@isar_multiarch_packages('IMAGE_INSTALL', d)}"
ROOTFS_MANIFEST_DEPLOY_DIR ?= "${DEPLOY_DIR_IMAGE}"
ROOTFS_DPKGSTATUS_DEPLOY_DIR ?= "${DEPLOY_DIR_IMAGE}"
ROOTFS_PACKAGE_SUFFIX ?= "${PN}-${DISTRO}-${MACHINE}"

ROOTFS_POSTPROCESS_COMMAND:prepend = "${@bb.utils.contains('BASE_REPO_FEATURES', 'cache-deb-src', 'cache_deb_src', '', d)} "

inherit rootfs
inherit sdk
inherit image-tools-extension
inherit image-postproc-extension
inherit image-locales-extension
inherit image-account-extension

# Extra space for rootfs in MB
ROOTFS_EXTRA ?= "64"

def get_rootfs_size(d):
    import subprocess
    rootfs_extra = int(d.getVar("ROOTFS_EXTRA"))

    output = subprocess.check_output(
        ["sudo", "du", "-xs", "--block-size=1k", d.getVar("IMAGE_ROOTFS")]
    )
    base_size = int(output.split()[0])

    return base_size + rootfs_extra * 1024

python set_image_size () {
    rootfs_size = get_rootfs_size(d)
    d.setVar('ROOTFS_SIZE', str(rootfs_size))
    d.setVarFlag('ROOTFS_SIZE', 'export', '1')
}

def get_base_type(t, d):
    bt = t
    for c in d.getVar('IMAGE_CONVERSIONS').split():
        if t.endswith('.' + c):
            bt = t[:-len('.' + c)]
            break
    return bt if bt == t else get_base_type(bt, d)

# Calculate IMAGE_BASETYPES as list of all image types that need to be built,
# also due to dependencies, but withoug any conversions.
# This is only for use in imagetype classes, e.g., for conditional expressions
# in the form of "${@bb.utils.contains('IMAGE_BASETYPES', type, a, b, d)}"
# All this dependency resolution (including conversions) is then done again
# below when the actual image tasks are constructed.
def get_image_basetypes(d):
    def recurse(t):
        bt = get_base_type(t, d)
        deps = (d.getVar('IMAGE_TYPEDEP:' + bt.replace('-', '_').replace('.', '_')) or '').split()
        ret = set([bt])
        for dep in deps:
            ret |= recurse(dep)
        return ret
    basetypes = set()
    for t in (d.getVar('IMAGE_FSTYPES') or '').split():
        basetypes |= recurse(t)
    return ' '.join(list(basetypes))

IMAGE_BASETYPES = "${@get_image_basetypes(d)}"

# image types
IMAGE_CLASSES ??= ""
IMGCLASSES = "imagetypes imagetypes_wic imagetypes_vm imagetypes_container"
IMGCLASSES += "${IMAGE_CLASSES}"
inherit ${IMGCLASSES}

# convenience variables to be used by CMDs
IMAGE_FILE_HOST = "${DEPLOY_DIR_IMAGE}/${IMAGE_FULLNAME}.${type}"
IMAGE_FILE_CHROOT = "${PP_DEPLOY}/${IMAGE_FULLNAME}.${type}"
SUDO_CHROOT = "imager_run -d ${PP_ROOTFS} -u root --"

# hook up IMAGE_CMD_*
python() {
    image_types = (d.getVar('IMAGE_FSTYPES') or '').split()
    conversions = set(d.getVar('IMAGE_CONVERSIONS').split())

    basetypes = {}
    typedeps = {}
    vardeps = set()

    def collect_image_type(t):
        bt = get_base_type(t, d)

        if bt not in basetypes:
            basetypes[bt] = []
        if t not in basetypes[bt]:
            basetypes[bt].append(t)
        t_clean = t.replace('-', '_').replace('.', '_')
        deps = (d.getVar('IMAGE_TYPEDEP:' + t_clean) or '').split()
        vardeps.add('IMAGE_TYPEDEP:' + t_clean)
        if bt not in typedeps:
            typedeps[bt] = set()
        for dep in deps:
            if dep not in image_types:
                image_types.append(dep)
            collect_image_type(dep)
            typedeps[bt].add(get_base_type(dep, d))
        if bt != t:
            collect_image_type(bt)

    for t in image_types[:]:
        collect_image_type(t)

    # TODO: OE uses do_image, but Isar is different...
    d.appendVarFlag('do_image_tools', 'vardeps', ' '.join(vardeps))

    imager_install = set()
    imager_build_deps = set()
    conversion_install = set()
    for bt in basetypes:
        local_imager_install = set()
        local_conversion_install = set()
        vardeps = set()
        cmds = []
        bt_clean = bt.replace('-', '_').replace('.', '_')

        # prepare local environment
        localdata = bb.data.createCopy(d)
        localdata.setVar('OVERRIDES', bt_clean + ':' + d.getVar('OVERRIDES', False))
        localdata.setVar('PV', d.getVar('PV'))
        localdata.delVar('DATETIME')
        localdata.delVar('DATE')
        localdata.delVar('TMPDIR')
        vardepsexclude = (d.getVarFlag('IMAGE_CMD:' + bt_clean, 'vardepsexclude', True) or '').split()
        for dep in vardepsexclude:
            localdata.delVar(dep)

        # check if required args are set
        required_args = (localdata.getVar('IMAGE_CMD_REQUIRED_ARGS') or '').split()
        if any([d.getVar(arg) is None for arg in required_args]):
            bb.fatal("IMAGE_FSTYPE '%s' requires these arguments: %s" % (image_type, ', '.join(required_args)))

        # imager install
        for dep in (d.getVar('IMAGER_INSTALL:' + bt_clean) or '').split():
            imager_install.add(dep)
            local_imager_install.add(dep)
        for dep in (d.getVar('IMAGER_BUILD_DEPS:' + bt_clean) or '').split():
            imager_build_deps.add(dep)

        # construct image command
        image_cmd = localdata.getVar('IMAGE_CMD:' + bt_clean)
        if image_cmd:
            localdata.setVar('type', bt)
            cmds.append(localdata.expand(image_cmd))
            cmds.append(localdata.expand('\tsudo chown $(id -u):$(id -g) ${IMAGE_FILE_HOST}'))
        else:
            bb.fatal("No IMAGE_CMD for %s" % bt)
        vardeps.add('IMAGE_CMD:' + bt_clean)
        d.delVarFlag('IMAGE_CMD:' + bt_clean, 'func')
        task_deps = d.getVarFlag('IMAGE_CMD:' + bt_clean, 'depends')

        image_src = localdata.getVar('IMAGE_SRC_URI:' + bt_clean)
        if image_src:
            d.appendVar("SRC_URI", ' ' + image_src)

        image_tmpl_files = localdata.getVar('IMAGE_TEMPLATE_FILES:' + bt_clean)
        image_tmpl_vars = localdata.getVar('IMAGE_TEMPLATE_VARS:' + bt_clean)
        if image_tmpl_files:
            d.appendVar("TEMPLATE_FILES", ' ' + image_tmpl_files)
        if image_tmpl_vars:
            d.appendVar("TEMPLATE_VARS", ' ' + image_tmpl_vars)

        # add conversions
        conversion_depends = set()
        rm_images = set()
        def create_conversions(t):
            for c in sorted(conversions):
                if t.endswith('.' + c):
                    t = t[:-len(c) - 1]
                    create_conversions(t)
                    localdata.setVar('type', t)
                    cmd = '\t' + localdata.getVar('CONVERSION_CMD:' + c)
                    if cmd not in cmds:
                        cmds.append(cmd)
                        cmds.append(localdata.expand('\tsudo chown $(id -u):$(id -g) ${IMAGE_FILE_HOST}.%s' % c))
                    vardeps.add('CONVERSION_CMD:' + c)
                    for dep in (localdata.getVar('CONVERSION_DEPS:' + c) or '').split():
                        conversion_install.add(dep)
                        local_conversion_install.add(dep)
                    # remove temporary image files
                    if t not in image_types:
                        rm_images.add(localdata.expand('${IMAGE_FILE_HOST}'))

        for t in basetypes[bt]:
            create_conversions(t)

        if bt not in image_types:
            localdata.setVar('type', t)
            rm_images.add(localdata.expand('${IMAGE_FILE_HOST}'))

        for image in rm_images:
            cmds.append('\trm ' + image)

        # image type dependencies
        after = 'do_image_tools'
        for dep in typedeps[bt]:
            after += ' do_image_%s' % dep.replace('-', '_').replace('.', '_')

        # create the task
        task = 'do_image_%s' % bt_clean
        d.setVar(task, '\n'.join(cmds))
        d.setVarFlag(task, 'func', '1')
        d.setVarFlag(task, 'network', localdata.expand('${TASK_USE_SUDO}'))
        d.appendVarFlag(task, 'prefuncs', ' set_image_size')
        d.appendVarFlag(task, 'vardeps', ' ' + ' '.join(vardeps))
        d.appendVarFlag(task, 'vardepsexclude', ' ' + ' '.join(vardepsexclude))
        d.appendVarFlag(task, 'dirs', localdata.expand(' ${DEPLOY_DIR_IMAGE}'))
        if task_deps:
            d.appendVarFlag(task, 'depends', task_deps)
        bb.build.addtask(task, 'do_image', after, d)

        # set per type imager dependencies
        d.setVar('INSTALL_image_%s' % bt_clean, d.getVar('IMAGER_INSTALL'))
        d.appendVar('INSTALL_image_%s' % bt_clean, ' ' + ' '.join(sorted(local_imager_install | local_conversion_install)))

    d.appendVar('IMAGER_INSTALL', ' ' + ' '.join(sorted(imager_install | conversion_install)))
    d.appendVar('IMAGER_BUILD_DEPS', ' ' + ' '.join(sorted(imager_build_deps)))
}

# here we call a command that should describe your whole build system,
# this could be "git describe" or something similar.
# set ISAR_RELEASE_CMD to customize, or override do_mark_rootfs to do something
# completely different
get_build_id[vardepsexclude] += "BBLAYERS"
get_build_id() {
	if [ $(echo ${BBLAYERS} | wc -w) -ne 2 ] &&
	   [ "${ISAR_RELEASE_CMD}" = "${ISAR_RELEASE_CMD_DEFAULT}" ]; then
		bbwarn "You are using external layers that will not be" \
		       "considered in the build_id. Consider changing" \
		       "ISAR_RELEASE_CMD."
	fi
	if ! ( ${ISAR_RELEASE_CMD} ) 2>/dev/null; then
		bbwarn "\"${ISAR_RELEASE_CMD}\" failed, returning empty build_id."
		echo ""
	fi
}

ROOTFS_CONFIGURE_COMMAND += "image_configure_fstab"
image_configure_fstab[weight] = "2"
image_configure_fstab() {
    sudo tee '${IMAGE_ROOTFS}/etc/fstab' << EOF
# Begin /etc/fstab
proc		/proc		proc		nosuid,noexec,nodev	0	0
sysfs		/sys		sysfs		nosuid,noexec,nodev	0	0
devpts		/dev/pts	devpts		gid=5,mode=620		0	0
tmpfs		/run		tmpfs		defaults		0	0
devtmpfs	/dev		devtmpfs	mode=0755,nosuid	0	0

# End /etc/fstab
EOF
}

# Default kernel, initrd and dtb image deploy paths (inside imager)
KERNEL_IMG = "${PP_DEPLOY}/${KERNEL_IMAGE}"
INITRD_IMG = "${PP_DEPLOY}/${INITRD_DEPLOY_FILE}"
# only one dtb file supported, pick the first
DTB_IMG = "${PP_DEPLOY}/${@(d.getVar('DTB_FILES').split() or [''])[0]}"

do_copy_boot_files[cleandirs] += "${DEPLOYDIR}"
do_copy_boot_files[sstate-inputdirs] = "${DEPLOYDIR}"
do_copy_boot_files[sstate-outputdirs] = "${DEPLOY_DIR_IMAGE}"
do_copy_boot_files[network] = "${TASK_USE_SUDO}"
do_copy_boot_files() {
    kernel="$(realpath -q '${IMAGE_ROOTFS}'/vmlinu[xz])"
    if [ ! -f "$kernel" ]; then
        kernel="$(realpath -q '${IMAGE_ROOTFS}'/boot/vmlinu[xz])"
    fi
    if [ -f "$kernel" ]; then
        sudo cat "$kernel" > "${DEPLOYDIR}/${KERNEL_IMAGE}"
    fi

    if [ -z "${INITRD_IMAGE}" ]; then
        # deploy default initrd if no custom one is build
        initrd="$(realpath -q '${IMAGE_ROOTFS}/initrd.img')"
        if [ ! -f "$initrd" ]; then
            initrd="$(realpath -q '${IMAGE_ROOTFS}/boot/initrd.img')"
        fi
        if [ -f "$initrd" ]; then
            cp -f "$initrd" '${DEPLOYDIR}/${INITRD_DEPLOY_FILE}'
        fi
    fi

    for file in ${DTB_FILES}; do
        dtb="$(find '${IMAGE_ROOTFS}/usr/lib' -type f \
                    -iwholename '*linux-image-*/'${file} | head -1)"

        if [ -z "$dtb" -o ! -e "$dtb" ]; then
            die "${file} not found"
        fi

        cp -f "$dtb" "${DEPLOYDIR}/"
    done
}
addtask copy_boot_files before do_rootfs_postprocess after do_rootfs_install

python do_copy_boot_files_setscene () {
    sstate_setscene(d)
}
addtask do_copy_boot_files_setscene

python do_image_tools() {
    """Virtual task"""
    pass
}
addtask image_tools before do_build after do_rootfs

# all imagetypes are depend on schroot and isar-apt
do_image_tools[depends] = "${SCHROOT_DEP} isar-apt:do_cache_config"
do_image_tools[deptask] = "do_deploy_deb"

python do_image() {
    """Virtual task"""
    pass
}
addtask image before do_build after do_image_tools

python do_deploy() {
    """Virtual task"""
    pass
}
addtask deploy before do_build after do_image

def apt_list_files(d):
    lists = []
    sources = d.getVar("SRC_URI").split()
    for s in sources:
        _, _, local, _, _, parm = bb.fetch.decodeurl(s)
        base, ext = os.path.splitext(os.path.basename(local))
        if ext and ext in (".list"):
            lists.append(local)
    return lists

IMAGE_LISTS = "${@ ' '.join(apt_list_files(d)) }"

do_rootfs_finalize() {
    sudo -s <<'EOSUDO'
        set -e

        if [ -e "${ROOTFSDIR}/chroot-setup.sh" ]; then
            "${ROOTFSDIR}/chroot-setup.sh" "cleanup" "${ROOTFSDIR}"
        fi
        rm -f "${ROOTFSDIR}/chroot-setup.sh"

        if [ ! -e "${ROOTFSDIR}/usr/share/doc/qemu-user-static" ]; then
            find "${ROOTFSDIR}/usr/bin" \
                -maxdepth 1 -name 'qemu-*-static' -type f -delete
        fi

        if mountpoint -q '${ROOTFSDIR}/isar-apt'; then
            umount '${ROOTFSDIR}/isar-apt'
            rmdir --ignore-fail-on-non-empty ${ROOTFSDIR}/isar-apt
        fi

        if mountpoint -q '${ROOTFSDIR}/base-apt'; then
            umount '${ROOTFSDIR}/base-apt'
            rmdir --ignore-fail-on-non-empty ${ROOTFSDIR}/base-apt
        fi

        if mountpoint -q '${ROOTFSDIR}/dev/pts'; then
            umount '${ROOTFSDIR}/dev/pts'
        fi
        if mountpoint -q '${ROOTFSDIR}/dev/shm'; then
            umount '${ROOTFSDIR}/dev/shm'
        fi
        if mountpoint -q '${ROOTFSDIR}/dev'; then
            umount '${ROOTFSDIR}/dev'
        fi
        if mountpoint -q '${ROOTFSDIR}/proc'; then
            umount '${ROOTFSDIR}/proc'
        fi
        if mountpoint -q '${ROOTFSDIR}/sys'; then
            umount '${ROOTFSDIR}/sys'
        fi

        if [ -e "${ROOTFSDIR}/etc/apt/sources-list" ]; then
            mv "${ROOTFSDIR}/etc/apt/sources-list" \
                "${ROOTFSDIR}/etc/apt/sources.list.d/bootstrap.list"
        fi
        if [ -n "${IMAGE_LISTS}" ]; then
            rm -f "${ROOTFSDIR}/etc/apt/sources.list.d/bootstrap.list"
            for l in ${IMAGE_LISTS}; do
                cp "${WORKDIR}"/${l} "${ROOTFSDIR}/etc/apt/sources.list.d/"
            done
        fi

        rm -f "${ROOTFSDIR}/run/blkid/blkid.tab"
        rm -f "${ROOTFSDIR}/run/blkid/blkid.tab.old"
EOSUDO

    # Sometimes qemu-user-static generates coredumps in chroot, move them
    # to work temporary directory and inform user about it.
    for f in $(sudo find ${ROOTFSDIR} -type f -name *.core -exec file --mime-type {} \; | grep 'application/x-coredump' | cut -d: -f1); do
        sudo mv "${f}" "${WORKDIR}/temp/"
        bbwarn "found core dump in rootfs, check it in ${WORKDIR}/temp/${f##*/}"
    done

    # Set same time-stamps to the newly generated file/folders in the
    # rootfs image for the purpose of reproducible builds.
    sudo find ${ROOTFSDIR} -newermt "$(date -d@${SOURCE_DATE_EPOCH} '+%Y-%m-%d %H:%M:%S')" \
        -exec touch '{}' -h -d@${SOURCE_DATE_EPOCH} ';'
}
do_rootfs_finalize[network] = "${TASK_USE_SUDO}"
addtask rootfs_finalize before do_rootfs after do_rootfs_postprocess

ROOTFS_QA_FIND_ARGS ?= ""

do_rootfs_quality_check() {
    rootfs_install_stamp=$( ls -1 "${STAMP}".do_rootfs_install* | head -1 )
    test -f "$rootfs_install_stamp"

    args="${ROOTFS_QA_FIND_ARGS}"
    # rootfs_finalize chroot-setup.sh
    args="${args} ! -path ${ROOTFSDIR}/var/lib/dpkg/diversions"
    for cmd in ${ROOTFS_POSTPROCESS_COMMAND}; do
        case "${cmd}" in
	    image_postprocess_mark)
	        args="${args} ! -path ${ROOTFSDIR}/etc/os-release";;
	    image_postprocess_machine_id)
	        args="${args} ! -path ${ROOTFSDIR}/etc/machine-id";;
	    image_postprocess_accounts)
	        args="${args} ! -path ${ROOTFSDIR}/etc/passwd \
                          ! -path ${ROOTFSDIR}/etc/passwd- \
                          ! -path ${ROOTFSDIR}/etc/subgid \
                          ! -path ${ROOTFSDIR}/etc/subgid- \
                          ! -path ${ROOTFSDIR}/etc/subuid \
                          ! -path ${ROOTFSDIR}/etc/subuid- \
                          ! -path ${ROOTFSDIR}/etc/gshadow \
                          ! -path ${ROOTFSDIR}/etc/gshadow- \
                          ! -path ${ROOTFSDIR}/etc/shadow \
                          ! -path ${ROOTFSDIR}/etc/shadow- \
                          ! -path ${ROOTFSDIR}/etc/group \
                          ! -path ${ROOTFSDIR}/etc/group-"
            ;;
	esac
    done
    found=$( sudo find ${ROOTFSDIR} -type f -newer $rootfs_install_stamp $args )
    if [ -n "$found" ]; then
        bbwarn "Files changed after package install. The following files seem"
	bbwarn "to have changed where they probably should not have."
	bbwarn "You might have a custom task or writing POSTPROCESS function."
	bbwarn "$found"
    fi
}
do_rootfs_quality_check[network] = "${TASK_USE_SUDO}"

addtask rootfs_quality_check after do_rootfs_finalize before do_rootfs
