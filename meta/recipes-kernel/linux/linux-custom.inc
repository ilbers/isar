# Custom kernel build
#
# This software is a part of ISAR.
# Copyright (c) Siemens AG, 2018
# Copyright (c) Mentor Graphics, a Siemens business, 2019
#
# SPDX-License-Identifier: MIT

# Settings that would typically be done from the custom kernel recipe
# -------------------------------------------------------------------

CHANGELOG_V = "${PV}+${PR}"
DESCRIPTION ?= "Custom kernel"
MAINTAINER ?= "isar-users <isar-users@googlegroups.com>"

KBUILD_DEPENDS ?= "build-essential:native, \
                   libelf-dev:native, \
                   libncurses-dev:native, \
                   libssl-dev:native, \
                   bc, \
                   bison, \
                   cpio, \
                   flex, \
                   git, \
                   kmod,"

KERNEL_DEBIAN_DEPENDS ?= "initramfs-tools | linux-initramfs-tool, \
                          kmod, \
                          linux-base (>= 4.3~),"

KERNEL_HEADERS_DEBIAN_DEPENDS ?= "libc6, \
                                  libssl1.1,"

KERNEL_LIBC_DEV_DEPLOY ?= "0"

# Settings that may be changed on a per distro, machine or layer basis
# --------------------------------------------------------------------

LINUX_VERSION_EXTENSION ?= ""

KERNEL_DEFCONFIG ??= ""

# Add our template meta-data to the sources
FILESEXTRAPATHS_prepend := "${FILE_DIRNAME}/files:"
SRC_URI += "file://debian"

# Variables and files that make our templates
# -------------------------------------------

TEMPLATE_FILES += "                  \
    debian/control.tmpl              \
    debian/isar/build.tmpl           \
    debian/isar/clean.tmpl           \
    debian/isar/common.tmpl          \
    debian/isar/configure.tmpl       \
    debian/isar/install.tmpl         \
    debian/isar/version.cfg.tmpl     \
    debian/linux-image.postinst.tmpl \
    debian/linux-image.postrm.tmpl   \
    debian/linux-image.preinst.tmpl  \
    debian/linux-image.prerm.tmpl    \
    debian/rules.tmpl                \
"

TEMPLATE_VARS += "                \
    HOST_ARCH                     \
    KBUILD_DEPENDS                \
    KERNEL_ARCH                   \
    KERNEL_DEBIAN_DEPENDS         \
    KERNEL_BUILD_DIR              \
    KERNEL_FILE                   \
    KERNEL_HEADERS_DEBIAN_DEPENDS \
    LINUX_VERSION_EXTENSION       \
    KERNEL_NAME_PROVIDED          \
    KERNEL_CONFIG_TARGET          \
    KERNEL_CONFIG_FRAGMENTS       \
"

inherit dpkg
inherit template

# Derive name of the kernel packages from the name of this recipe
KERNEL_NAME_PROVIDED ?= "${@ d.getVar('PN', True).partition('linux-')[2]}"

# Make bitbake know we will be producing linux-image and linux-headers packages
python() {
    kernel_name = d.getVar("KERNEL_NAME_PROVIDED", True)
    d.setVar('PROVIDES', 'linux-image-' + kernel_name + ' ' + \
                         'linux-headers-' + kernel_name)
}

def get_kernel_arch(d):
    distro_arch = d.getVar("DISTRO_ARCH")
    if distro_arch in ["amd64", "i386"]:
        kernel_arch = "x86"
    elif distro_arch == "arm64":
        kernel_arch = "arm64"
    elif distro_arch == "armhf":
        kernel_arch = "arm"
    elif distro_arch == "mipsel":
        kernel_arch = "mips"
    elif distro_arch == "riscv64":
        kernel_arch = "riscv"
    else:
        kernel_arch = ""
    return kernel_arch

KERNEL_ARCH ??= "${@get_kernel_arch(d)}"

def config_fragments(d):
    fragments = []
    sources = d.getVar("SRC_URI").split()
    for s in sources:
        _, _, local, _, _, parm = bb.fetch.decodeurl(s)
        apply = parm.get("apply")
        if apply == "no":
            continue
        base, ext = os.path.splitext(os.path.basename(local))
        if ext and ext in (".cfg"):
            fragments.append(local)
    return fragments

def get_additional_build_profiles(d):
    profiles = d.getVar('BASE_DISTRO', True)
    if d.getVar('KERNEL_LIBC_DEV_DEPLOY', True) != '1':
        profiles += ' nolibcdev'
    return profiles

DEB_BUILD_PROFILES += "${@get_additional_build_profiles(d)}"

do_prepare_build_prepend() {
	# copy meta-data over to source tree
	rm -rf ${S}/debian
	cp -r ${WORKDIR}/debian ${S}/

	# remove templates from the source tree
	find ${S}/debian -name *.tmpl | xargs rm -f

	# rename install/remove hooks to match user-specified name for our linux-image package
	mv ${S}/debian/linux-image.postinst ${S}/debian/linux-image-${KERNEL_NAME_PROVIDED}.postinst
	mv ${S}/debian/linux-image.postrm ${S}/debian/linux-image-${KERNEL_NAME_PROVIDED}.postrm
	mv ${S}/debian/linux-image.preinst ${S}/debian/linux-image-${KERNEL_NAME_PROVIDED}.preinst
	mv ${S}/debian/linux-image.prerm ${S}/debian/linux-image-${KERNEL_NAME_PROVIDED}.prerm

	# produce a changelog for our kernel build
	deb_add_changelog
}

# build directory for our "full" kernel build
KERNEL_BUILD_DIR = "build-full"

def get_kernel_config_target(d):
    kernel_defconfig = d.getVar('KERNEL_DEFCONFIG', True)

    config_target = kernel_defconfig

    if kernel_defconfig:
        workdir=d.getVar('WORKDIR', True)
        if os.path.isfile(workdir + "/" + kernel_defconfig):
            config_target = "olddefconfig"
        else:
            config_target = "defconfig KBUILD_DEFCONFIG=" + kernel_defconfig
    else:
        config_target = "defconfig"

    return config_target

KERNEL_CONFIG_TARGET = "${@get_kernel_config_target(d)}"

def get_kernel_config_fragments(d):
    src_frags = " ".join(config_fragments(d))
    out_frags = " ".join(map(lambda frag: 'debian/fragments/' + frag, config_fragments(d)))

    linux_version_extension = d.getVar('LINUX_VERSION_EXTENSION', True)
    if linux_version_extension:
        out_frags += " debian/isar/version.cfg"

    return out_frags

KERNEL_CONFIG_FRAGMENTS = "${@get_kernel_config_fragments(d)}"

dpkg_configure_kernel() {
	rm -rf ${S}/${KERNEL_BUILD_DIR} && mkdir -p ${S}/${KERNEL_BUILD_DIR}
	if [ -n "${KERNEL_DEFCONFIG}" ]; then
		if [ -e "${WORKDIR}/${KERNEL_DEFCONFIG}" ]; then
			cp ${WORKDIR}/${KERNEL_DEFCONFIG} ${S}/${KERNEL_BUILD_DIR}/.config
		fi
	fi

	# copy config fragments over to the kernel tree
	src_frags="${@ " ".join(config_fragments(d)) }"
	rm -rf ${S}/debian/fragments
	if [ -n "${src_frags}" ]; then
		mkdir -p ${S}/debian/fragments
		(cd ${WORKDIR} && cp ${src_frags} ${S}/debian/fragments/)
	fi
}

dpkg_runbuild_prepend() {
	dpkg_configure_kernel
}
