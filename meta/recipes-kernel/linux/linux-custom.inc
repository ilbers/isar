# Custom kernel build
#
# This software is a part of ISAR.
# Copyright (c) Siemens AG, 2022
# Copyright (c) Mentor Graphics, a Siemens business, 2022
#
# SPDX-License-Identifier: MIT

# Settings that would typically be done from the custom kernel recipe
# -------------------------------------------------------------------

CHANGELOG_V = "${PV}+${PR}"
DESCRIPTION ?= "Custom kernel"
MAINTAINER ?= "isar-users <isar-users@googlegroups.com>"
DISTRIBUTOR ?= "ISAR"

# pinned due to known or possible issues with compat 12
DEBIAN_COMPAT:buster = "10"

KBUILD_DEPENDS ?= "build-essential:native, \
                   libelf-dev:native, \
                   libncurses-dev:native, \
                   libssl-dev:native, \
                   bc, \
                   bison, \
                   cpio, \
                   dwarves, \
                   flex, \
                   git, \
                   kmod, \
                   linux-image-${KERNEL_NAME_PROVIDED}:${DISTRO_ARCH} <kbuild !kernel>, \
                   rsync,"

KERNEL_DEBIAN_DEPENDS ?= "initramfs-tools | linux-initramfs-tool, \
                          kmod, \
                          linux-base (>= 4.3~),"

KERNEL_HEADERS_DEBIAN_DEPENDS ?= ""

KERNEL_LIBC_DEV_ARCH_ALL = "0"
KERNEL_LIBC_DEV_ARCH_ALL:trixie = "1"
KERNEL_LIBC_DEV_DEPLOY ?= "0"

# Settings that may be changed on a per distro, machine or layer basis
# --------------------------------------------------------------------

LINUX_VERSION_EXTENSION ?= ""

KERNEL_DEFCONFIG ??= ""

HEADERS_INSTALL_EXTRA ??= ""

# Add our template meta-data to the sources
FILESPATH:append := ":${FILE_DIRNAME}/files"
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
    KBUILD_DEPENDS                \
    KERNEL_ARCH                   \
    KERNEL_DEBIAN_DEPENDS         \
    KERNEL_BUILD_DIR              \
    KERNEL_FILE                   \
    KERNEL_HEADERS_DEBIAN_DEPENDS \
    KERNEL_LIBC_DEV_ARCH          \
    LINUX_VERSION_EXTENSION       \
    KERNEL_NAME_PROVIDED          \
    KERNEL_CONFIG_FRAGMENTS       \
    KCFLAGS                       \
    KAFLAGS                       \
    DISTRIBUTOR                   \
    KERNEL_EXTRA_BUILDARGS        \
    HEADERS_INSTALL_EXTRA         \
    ISAR_ENABLE_COMPAT_ARCH       \
    COMPAT_DISTRO_ARCH            \
    DEBIAN_COMPAT                 \
"

inherit dpkg
inherit template
inherit kbuildtarget

# Add custom cflags to the kernel build
KCFLAGS ?= "-fdebug-prefix-map=${CURDIR}=."
KAFLAGS ?= "-fdebug-prefix-map=${CURDIR}=."

# Add extra arguments to the kernel build
KERNEL_EXTRA_BUILDARGS ??= ""

# Derive name of the kernel packages from the name of this recipe
KERNEL_NAME_PROVIDED ?= "${@ d.getVar('BPN').partition('linux-')[2]}"

# Determine cross-profile override
python() {
    if d.getVar("DISTRO_ARCH") != d.getVar("HOST_ARCH") and bb.utils.to_boolean(d.getVar("ISAR_CROSS_COMPILE")) and "class-native" not in d.getVar("OVERRIDES").split(":"):
        d.appendVar("OVERRIDES", ":cross-profile")
}

# Default profiles and provides
BUILD_PROFILES = "kernel kbuild"

# We only offer the -kbuildtarget variant when actually cross compiling
BBCLASSEXTEND:append:cross-profile = " kbuildtarget"

# When cross-profile is active:
# build only kernel (including config) with the default variant of the recipe
BUILD_PROFILES:cross-profile = "kernel"

# -native: kbuild package for host
BUILD_PROFILES:class-native = "kbuild"
RECIPE_PROVIDES:class-native = " \
    linux-headers-${KERNEL_NAME_PROVIDED} \
    linux-kbuild-${KERNEL_NAME_PROVIDED}"
# Use pseudo target to pull in the base variant of the recipe.
# Will be auto-extended with -native by multiarch.bbclass.
# Using DEPENDS instead of RDEPENDS to ensure creation of kernel including
# pregenerated kernel config before host specific linux-kbuild package build
DEPENDS:class-native += "${BPN}-pseudo"

# -kbuildtarget: kbuild package for target, enforcing non-cross-build
BUILD_PROFILES:class-kbuildtarget = "kbuild"
RECIPE_PROVIDES:class-kbuildtarget = " \
    linux-headers-${KERNEL_NAME_PROVIDED} \
    linux-kbuild-${KERNEL_NAME_PROVIDED}"
# Using DEPENDS instead of RDEPENDS to ensure creation of kernel including
# pregenerated kernel config before target specific linux-kbuild package build
DEPENDS:class-kbuildtarget = "${BPN}"
ISAR_CROSS_COMPILE:class-kbuildtarget = "0"

# Make bitbake know we will be producing linux-image and linux-headers packages
# Also make it know about other packages from control
RECIPE_PROVIDES = " \
    linux-image-${KERNEL_NAME_PROVIDED} \
    linux-headers-${KERNEL_NAME_PROVIDED} \
    linux-libc-dev \
    linux-libc-dev-${KERNEL_NAME_PROVIDED} \
    linux-libc-dev-${DISTRO_ARCH}-cross \
    linux-libc-dev-${DISTRO_ARCH}-cross-${KERNEL_NAME_PROVIDED} \
    linux-image-${KERNEL_NAME_PROVIDED}-dbg \
    linux-kbuild-${KERNEL_NAME_PROVIDED} \
    ${BPN}-pseudo-native \
"
# When cross-profile is active:
# kbuild package is provided by -native or -kbuildtarget variant. Also headers
# provisioning moves over to ensure those variants are pulled, although the
# package itself is still built by the base recipe.
RECIPE_PROVIDES:remove:cross-profile = " \
    linux-headers-${KERNEL_NAME_PROVIDED} \
    linux-kbuild-${KERNEL_NAME_PROVIDED}"

# As the multiarch class will not append -compat to -pseudo-native, we end up
# with two providers of it. Remove the wrong one.
RECIPE_PROVIDES:remove:class-compat = "${BPN}-pseudo-native"

# Append headers depends
HEADERS_DEPENDS = ", linux-kbuild-${KERNEL_NAME_PROVIDED} | linux-kbuild-${KERNEL_NAME_PROVIDED}-${DISTRO_ARCH}-cross"
KERNEL_HEADERS_DEBIAN_DEPENDS:append = "${HEADERS_DEPENDS}"

# Append provides
PROVIDES += "${RECIPE_PROVIDES}"

# Append build profiles
DEB_BUILD_PROFILES += "${BUILD_PROFILES}"

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

# set KERNEL_FILE without depending on package arch used in bitbake.conf
KERNEL_FILE:forcevariable = "${@ 'vmlinux' if d.getVar('KERNEL_ARCH') in ['mipsel', 'riscv', 'arm64'] else 'vmlinuz'}"

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
    profiles = d.getVar('BASE_DISTRO')
    if not bb.utils.to_boolean(d.getVar('KERNEL_LIBC_DEV_DEPLOY')):
        profiles += ' nolibcdev'
    elif bb.utils.to_boolean(d.getVar('KERNEL_LIBC_DEV_ARCH_ALL')):
        profiles += ' libcdev-arch-all'
    return profiles

KERNEL_LIBC_DEV_ARCH = "${@ bb.utils.contains('DEB_BUILD_PROFILES', 'libcdev-arch-all', 'all', 'any', d) }"
DEB_BUILD_PROFILES += "${@get_additional_build_profiles(d)}"

do_prepare_build:prepend() {
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

	# make sure user-specified directories do exist in ${S}
	if [ -n "${HEADERS_INSTALL_EXTRA}" ]; then
		for d in ${HEADERS_INSTALL_EXTRA}; do
			[ -d ${S}/${d} ] || {
				bbfatal "HEADERS_INSTALL_EXTRA: '${d}' not found in \${S}!"
			}
		done
	fi
}

# build directory for our "full" kernel build
KERNEL_BUILD_DIR = "build-full"

def get_kernel_config_target(d):
    kernel_defconfig = d.getVar('KERNEL_DEFCONFIG')

    config_target = kernel_defconfig

    if kernel_defconfig:
        workdir=d.getVar('WORKDIR')
        if os.path.isfile(workdir + "/" + kernel_defconfig):
            config_target = "olddefconfig"
        else:
            config_target = "defconfig KBUILD_DEFCONFIG=" + kernel_defconfig
    else:
        config_target = "defconfig"

    return config_target

def get_kernel_config_fragments(d):
    src_frags = " ".join(config_fragments(d))
    out_frags = " ".join(map(lambda frag: 'debian/fragments/' + frag, config_fragments(d)))

    linux_version_extension = d.getVar('LINUX_VERSION_EXTENSION')
    if linux_version_extension:
        out_frags += " debian/isar/version.cfg"

    return out_frags

KERNEL_CONFIG_FRAGMENTS = "${@get_kernel_config_fragments(d)}"

dpkg_configure_kernel() {
	grep -q "KERNEL_CONFIG_TARGET=" ${S}/debian/isar/configure ||
		cat << EOF | sed -i '/^do_configure() {/ r /dev/stdin' ${S}/debian/isar/configure
    KERNEL_CONFIG_TARGET="${@get_kernel_config_target(d)}"
EOF

	rm -rf ${S}/${KERNEL_BUILD_DIR} && mkdir -p ${S}/${KERNEL_BUILD_DIR}
	if [ -n "${KERNEL_DEFCONFIG}" ]; then
		if [ -e "${WORKDIR}/${KERNEL_DEFCONFIG}" ]; then
			cp ${WORKDIR}/${KERNEL_DEFCONFIG} ${S}/${KERNEL_BUILD_DIR}/.config
		fi
	fi

	# copy config fragments over to the kernel tree
	src_frags="${@ " ".join(config_fragments(d)) }"
	rm -rf ${S}/debian/fragments
	for frag in ${src_frags}; do
		basedir=$(dirname ${frag})
		mkdir -p ${S}/debian/fragments/${basedir}
		cp ${WORKDIR}/${frag} ${S}/debian/fragments/${basedir}/
	done
}

get_localversion_auto() {
	if grep -q "^CONFIG_LOCALVERSION_AUTO=y" ${S}/${KERNEL_BUILD_DIR}/.config; then
		cd ${S}
		if head=$(git rev-parse --verify --short HEAD 2>/dev/null); then
			echo "-g${head}" >${S}/.scmversion
		fi
	fi
}

do_dpkg_source:prepend() {
	dpkg_configure_kernel
	get_localversion_auto
}
