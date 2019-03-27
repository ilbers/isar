# Root filesystem for packages building
#
# This software is a part of ISAR.
# Copyright (C) 2015-2018 ilbers GmbH

DESCRIPTION = "Isar development filesystem for host"

require buildchroot.inc

BUILDCHROOT_PREINSTALL ?= "make \
                           debhelper \
                           autotools-dev \
                           dpkg \
                           locales \
                           docbook-to-man \
                           apt \
                           automake \
                           devscripts \
                           equivs \
                           libc6:${DISTRO_ARCH}"

# According to the wiki page:
#     https://wiki.debian.org/CrossToolchains
BUILDCHROOT_PREINSTALL_append_armhf += "binutils-arm-linux-gnueabihf \
                                        crossbuild-essential-armhf"
BUILDCHROOT_PREINSTALL_append_arm64 += "binutils-aarch64-linux-gnu \
                                        crossbuild-essential-arm64"


PARAMS = "--host-arch --host-distro"
do_build[depends] = "isar-apt:do_cache_config isar-bootstrap-host:do_bootstrap"
