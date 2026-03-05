# This software is a part of Isar.
# Copyright (C) 2026 ilbers GmbH
#
# SPDX-License-Identifier: MIT

MAINTAINER = "isar-users <isar-users@googlegroups.com>"

inherit initramfs-hook

# -----------------------------------------------------------------------------
# This recipe serves as an example workaround to add missing drivers to
# the initramfs generated for Debian Trixie. The drivers are missing due
# to an upstream bug in glibc/qemu. This issue caused booting issue on
# several Trixie targets.
#
# Background:
#
# Starting with Debian Trixie, update-initramfs invokes "dracut-install"
# to collect and install required drivers into the generated initramfs.
# "dracut-install" relies on fts_open() / fts_read() from glibc to
# traverse directories and locate drivers.
#
# Due to a long-standing bug [1] between qemu and glibc, the fts_*
# functions may fail to find files on certain 32-bit architectures. As a
# result, some required modules are not detected and not added to the
# initramfs. The produced image then fails to boot.
#
# It's known that at least these targets under Trixie are affected:
# - qemuarm (missing virtio_blk)
# - bananapi (missing sunxi_mmc)
# - nanopi-neo (missing sunxi_mmc)
#
# A similiar dracut bug report was filed in 2024 [2], pointing to this
# upstream glibc issue reported in 2018 [1]. No upstream fix has been
# applied, and the issue appears to affect only qemu builds for specific
# 32-bit targets.
#
# [1] https://sourceware.org/bugzilla/show_bug.cgi?id=23960
# [2] https://bugs-devel.debian.org/cgi-bin/bugreport.cgi?bug=1079443
#
# Purpose of this recipe:
#
# This recipe provides a temporary workaround by using a customized
# initramfs hook to append drivers that are currently missing from
# the initramfs, allowing the target to boot.
# Notes for dracut users:
#
# This workaround applies only to initramfs images generated with
# initramfs-tools. It does not apply to initramfs images generated
# directly with dracut.
#
# When using dracut, drivers may also be missing due to the same
# underlying glibc/qemu issue. However, the set of missing drivers
# may differ from those observed with initramfs-tools.
#
# This hook recipe cannot be used together with dracut, as it requires
# initramfs-tools to be installed, and dracut conflicts with
# initramfs-tools.
# -----------------------------------------------------------------------------

HOOK_ADD_MODULES:append:qemuarm:debian-trixie = "virtio-blk"
HOOK_ADD_MODULES:append:bananapi:debian-trixie = "sunxi_mmc"
HOOK_ADD_MODULES:append:nanopi-neo:debian-trixie = "sunxi_mmc"
