# Root filesystem for packages building
# Example of SBUILD_FLAVOR usage with docbook-to-man preinstalled
#
# This software is a part of ISAR.
# Copyright (C) 2023 ilbers GmbH

DESCRIPTION = "Isar sbuild/schroot filesystem for target (docbook-to-man)"

require recipes-devtools/sbuild-chroot/sbuild-chroot-target.bb

SBUILD_FLAVOR = "db2m"
SBUILD_CHROOT_PREINSTALL_EXTRA ?= "docbook-to-man"
