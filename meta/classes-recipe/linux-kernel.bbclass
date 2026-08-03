# Custom kernel build
#
# This software is a part of Isar.
# Copyright (c) Siemens AG, 2022
# Copyright (c) Mentor Graphics, a Siemens business, 2022
#
# SPDX-License-Identifier: MIT

# Settings that would typically be done from the custom kernel recipe
# -------------------------------------------------------------------

CHANGELOG_V = "${PV}+${PR}"
DESCRIPTION ?= "Custom kernel"
MAINTAINER ?= "isar-users <isar-users@googlegroups.com>"
DISTRIBUTOR ?= "Isar"

# pinned due to known or possible issues with compat 12
DEBIAN_COMPAT:buster = "10"

KBUILD_DEPENDS ?= "libelf-dev:native, \
                   libncurses-dev:native, \
                   libssl-dev:native, \
                   bc, \
                   bison, \
                   cpio, \
                   dwarves, \
                   flex, \
                   gawk, \
                   git, \
                   kmod, \
                   linux-image-${KERNEL_NAME_PROVIDED}:${DISTRO_ARCH} <pkg.${BPN}.kbuild !pkg.${BPN}.kernel>, \
                   rsync,"

KERNEL_DEBIAN_DEPENDS ?= "initramfs-tools | linux-initramfs-tool | dracut, \
                          kmod, \
                          linux-base (>= 4.3~),"

KERNEL_HEADERS_DEBIAN_DEPENDS ?= ""

KERNEL_LIBC_DEV_ARCH_ALL = "1"
KERNEL_LIBC_DEV_ARCH_ALL:buster = "0"
KERNEL_LIBC_DEV_ARCH_ALL:bullseye = "0"
KERNEL_LIBC_DEV_ARCH_ALL:bookworm = "0"
KERNEL_LIBC_DEV_ARCH_ALL:ubuntu = "0"

KERNEL_LIBC_DEV_DEPLOY ?= "0"

# Settings that may be changed on a per distro, machine or layer basis
# --------------------------------------------------------------------

LINUX_VERSION_EXTENSION ?= ""

KERNEL_DEFCONFIG ??= ""

HEADERS_INSTALL_EXTRA ??= ""

# Add our template meta-data to the sources
FILESPATH:append = ":${LAYERDIR_core}/recipes-kernel/linux/files"
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
    BPN                           \
    KBUILD_DEPENDS                \
    KERNEL_ARCH                   \
    KERNEL_DEBIAN_DEPENDS         \
    KERNEL_BUILD_DIR              \
    KERNEL_FILE                   \
    KERNEL_HEADERS_DEBIAN_DEPENDS \
    KERNEL_LIBC_DEV_ARCH          \
    LINUX_VERSION_EXTENSION       \
    KERNEL_NAME_PROVIDED          \
    KCONFIG_FRAGMENTS             \
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
inherit kbuildtarget
inherit libctarget

# Add custom cflags to the kernel build
KCFLAGS ?= "-fdebug-prefix-map=${CURDIR}=."
KAFLAGS ?= "-fdebug-prefix-map=${CURDIR}=."

# Add extra arguments to the kernel build
KERNEL_EXTRA_BUILDARGS ??= ""

# Derive name of the kernel packages from the name of this recipe
KERNEL_NAME_PROVIDED ?= "${@ d.getVar('BPN').partition('linux-')[2]}"

# Determine cross-profile override
python() {
    if d.getVar("DISTRO_ARCH") != d.getVar("HOST_ARCH") and bb.utils.to_boolean(d.getVar("ISAR_CROSS_COMPILE")):
        if "class-native" in d.getVar("OVERRIDES").split(":"):
            # generating -cross packages (in HOST_ARCH) from a -native variant
            d.appendVar("OVERRIDES", ":cross-profile-native")
        else:
            d.appendVar("OVERRIDES", ":cross-profile")
}

# Default profiles and provides
BUILD_PROFILES = "pkg.${BPN}.kernel pkg.${BPN}.kbuild"

# We only offer the -kbuildtarget variant when actually cross compiling
BBCLASSEXTEND:append:cross-profile = " kbuildtarget"

# The arch=all linux-libc-dev packages cannot be built in the cross variant of
# the base recipe: sbuild is invoked with --no-arch-all there, so no arch=all
# binary packages are produced. In that situation, build them via a dedicated,
# native -libctarget variant. This condition is true only when libc-dev deployment
# is requested and the resulting package is arch=all.
KERNEL_LIBC_DEV_NEEDS_LIBC_VARIANT = "${@ '1' if bb.utils.to_boolean(d.getVar('KERNEL_LIBC_DEV_DEPLOY')) and bb.utils.to_boolean(d.getVar('KERNEL_LIBC_DEV_ARCH_ALL')) else '0'}"
BBCLASSEXTEND:append:cross-profile = "${@ ' libctarget' if bb.utils.to_boolean(d.getVar('KERNEL_LIBC_DEV_NEEDS_LIBC_VARIANT')) else ''}"

# When cross-profile is active:
# Build kernel (including config) cross packages (linux-libc-dev-*-cross)
# with the default variant of the recipe
BUILD_PROFILES:cross-profile = "pkg.${BPN}.kernel pkg.${BPN}.cross"

# -native: kbuild package for host, in cross variant if needed
BUILD_PROFILES:class-native = "pkg.${BPN}.kbuild"
BUILD_PROFILES:append:cross-profile-native = " pkg.${BPN}.cross"
RECIPE_PROVIDES:class-native = " \
    linux-headers-${KERNEL_NAME_PROVIDED} \
    linux-kbuild-${KERNEL_NAME_PROVIDED}"
# Use pseudo target to pull in the base variant of the recipe.
# Will be auto-extended with -native by multiarch.bbclass.
# Using DEPENDS instead of RDEPENDS to ensure creation of kernel including
# pregenerated kernel config before host specific linux-kbuild package build
DEPENDS:class-native += "${BPN}-pseudo"

# -kbuildtarget: kbuild package for target, enforcing non-cross-build
BUILD_PROFILES:class-kbuildtarget = "pkg.${BPN}.kbuild"
RECIPE_PROVIDES:class-kbuildtarget = " \
    linux-headers-${KERNEL_NAME_PROVIDED} \
    linux-kbuild-${KERNEL_NAME_PROVIDED}"
RECIPE_PROVIDES:remove:class-kbuildtarget = " \
    linux-libc-dev \
    linux-libc-dev-${DISTRO_ARCH}-cross"
# Using DEPENDS instead of RDEPENDS to ensure creation of kernel including
# pregenerated kernel config before target specific linux-kbuild package build
DEPENDS:class-kbuildtarget = "${BPN}"
# PACKAGE_ARCH stays at DISTRO_ARCH here, so this flag lets crossvars.bbclass
# pick the target chroot: the kbuild scripts/tools shipped by this variant
# must be target binaries. (The host binaries go into the separate
# linux-kbuild-*-<arch>-cross package built under pkg.${BPN}.cross.)
ISAR_CROSS_COMPILE:class-kbuildtarget = "0"

# The -libctarget variant builds only the (arch=all) linux-libc-dev packages.
# As these are arch=all packages, they are built natively for the host architecture
# (like -native). Setting PACKAGE_ARCH to HOST_ARCH makes crossvars.bbclass select
# the host chroot and a native (non-cross) build, so sbuild is invoked with
# --arch-all and produces the arch=all packages. The base cross recipe depends on it
# (see below) to get the packages built.
BUILD_PROFILES:class-libctarget = "pkg.${BPN}.libc"
RECIPE_PROVIDES:class-libctarget = " \
    linux-libc-dev \
    linux-libc-dev-${DISTRO_ARCH}-cross"
PACKAGE_ARCH:class-libctarget = "${HOST_ARCH}"
# Unlike -kbuildtarget above, this flag does not select the chroot here:
# It is only needed to keep the cross-profile override off this variant, which
# would otherwise clobber BUILD_PROFILES and apply the base recipe's
# "DEPENDS += ${BPN}-libctarget" to -libctarget itself, creating a dependency loop.
ISAR_CROSS_COMPILE:class-libctarget = "0"

# Make bitbake know we will be producing linux-image and linux-headers packages
# Also make it know about other packages from control
RECIPE_PROVIDES = " \
    linux-image-${KERNEL_NAME_PROVIDED} \
    linux-headers-${KERNEL_NAME_PROVIDED} \
    linux-image-${KERNEL_NAME_PROVIDED}-dbg \
    linux-kbuild-${KERNEL_NAME_PROVIDED} \
    ${BPN}-pseudo-native \
"

# Provide linux-libc-dev packages unless nolibcdev profile used
OVERRIDES:append = ":${@ bb.utils.contains('DEB_BUILD_PROFILES', 'pkg.{}.nolibcdev'.format(d.getVar('BPN')), '', 'libcdev', d)}"

# The base recipe provides the linux-libc-dev packages, except when they are
# arch=all and we are cross building: in that case they are built and provided
# by the dedicated -libctarget variant instead (see class-libctarget above), so
# the base recipe must not advertise them (it cannot build them here).
RECIPE_PROVIDES:append:libcdev = "${@ '' if bb.utils.to_boolean(d.getVar('KERNEL_LIBC_DEV_NEEDS_LIBC_VARIANT')) else ' linux-libc-dev'}"
RECIPE_PROVIDES:append:libcdev:cross-profile = "${@ '' if bb.utils.to_boolean(d.getVar('KERNEL_LIBC_DEV_NEEDS_LIBC_VARIANT')) else ' linux-libc-dev-${DISTRO_ARCH}-cross'}"

# When cross-profile is active:
# kbuild package is provided by -native or -kbuildtarget variant. Also headers
# provisioning moves over to ensure those variants are pulled, although the
# package itself is still built by the base recipe.
RECIPE_PROVIDES:remove:cross-profile = " \
    linux-headers-${KERNEL_NAME_PROVIDED} \
    linux-kbuild-${KERNEL_NAME_PROVIDED}"

# The arch=all linux-libc-dev packages are built by the -libctarget variant.
# Depend on it from the base cross recipe (linux-image-<arch>) so it is built.
DEPENDS:append:cross-profile = "${@ ' ${BPN}-libctarget' if bb.utils.to_boolean(d.getVar('KERNEL_LIBC_DEV_NEEDS_LIBC_VARIANT')) else ''}"

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

KERNEL_CONFIG_FRAGMENTS ?= ""

def config_fragments(d):
    fragments = d.getVar('KERNEL_CONFIG_FRAGMENTS').split()
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
        profiles += ' pkg.{}.nolibcdev'.format(d.getVar('BPN'))
    elif bb.utils.to_boolean(d.getVar('KERNEL_LIBC_DEV_ARCH_ALL')):
        profiles += ' pkg.{}.libcdev-arch-all'.format(d.getVar('BPN'))
    return profiles

KERNEL_LIBC_DEV_ARCH = "${@ bb.utils.contains('DEB_BUILD_PROFILES', 'pkg.{}.libcdev-arch-all'.format(d.getVar('BPN')), 'all\nMulti-Arch: foreign', 'any', d) }"
DEB_BUILD_PROFILES += "${@get_additional_build_profiles(d)}"

do_prepare_build[cleandirs] += "${S}/debian"
do_prepare_build:prepend() {
	# copy meta-data over to source tree
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

KERNEL_CONFIG_FRAGMENTS:append = " \
    ${@'${S}/debian/isar/version.cfg' if d.getVar('LINUX_VERSION_EXTENSION') else ''}"

def get_kernel_config_fragments(d):
    out_frags = ""
    S = d.getVar('S') + '/'
    for frag in config_fragments(d):
        if frag.startswith(S):
            out_frags += ' ' + frag[len(S):]
        else:
            out_frags += ' debian/fragments/' + frag
    return out_frags.strip()

# internal list of config fragments
KCONFIG_FRAGMENTS = "${@get_kernel_config_fragments(d)}"

dpkg_configure_kernel() {
	grep -q "KERNEL_CONFIG_TARGET=" ${S}/debian/isar/configure ||
		cat << EOF | sed -i '/^do_configure() {/ r /dev/stdin' ${S}/debian/isar/configure
    KERNEL_CONFIG_TARGET="${@get_kernel_config_target(d)}"
EOF

	if [ -n "${KERNEL_DEFCONFIG}" ]; then
		if [ -e "${WORKDIR}/${KERNEL_DEFCONFIG}" ]; then
			cp ${WORKDIR}/${KERNEL_DEFCONFIG} ${S}/${KERNEL_BUILD_DIR}/.config
		fi
	fi

	# copy config fragments over to the kernel tree
	src_frags="${@ " ".join(config_fragments(d)) }"
	for frag in ${src_frags}; do
		# skip frag if it starts with ${S}, thus is part of the sources
		if [ "${frag#${S}}" = "$frag" ]; then
			basedir=$(dirname ${frag})
			mkdir -p ${S}/debian/fragments/${basedir}
			cp ${WORKDIR}/${frag} ${S}/debian/fragments/${basedir}/
		fi
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

do_dpkg_source[cleandirs] += "${S}/${KERNEL_BUILD_DIR} ${S}/debian/fragments"
do_dpkg_source:prepend() {
	dpkg_configure_kernel
	get_localversion_auto
}
