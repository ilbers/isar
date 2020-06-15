#!/bin/sh
#
# Resize last partition to full medium size
#
# This software is a part of ISAR.
# Copyright (c) Siemens AG, 2018
#
# SPDX-License-Identifier: MIT

set -e

ROOT_DEV="$(findmnt / -o source -n)"
BOOT_DEV="$(echo "${ROOT_DEV}" | sed 's/p\?[0-9]*$//')"

if [ "${ROOT_DEV}" = "${BOOT_DEV}" ]; then
	echo "Boot device equals root device - no partitioning found" >&2
	exit 1
fi

LAST_PART="$(sfdisk -d "${BOOT_DEV}" 2>/dev/null | tail -1 | cut -d ' ' -f 1)"

# Transform the partition table as follows:
#
# - Remove any 'last-lba' header so sfdisk uses the entire available space.
# - If this partition table is MBR and an extended partition container (EBR)
#   exists, we assume this needs to be expanded as well; remove its size
#   field so sfdisk expands it.
# - For the previously fetched last partition, also remove the size field so
#   sfdisk expands it.
sfdisk -d "${BOOT_DEV}" 2>/dev/null | \
	grep -v last-lba | \
	sed 's|^\(.*, \)size=[^,]*, \(type=[f5]\)$|\1\2|' | \
	sed 's|^\('"${LAST_PART}"' .*, \)size=[^,]*, |\1|' | \
	sfdisk --force "${BOOT_DEV}"

# Inform the kernel about the partitioning change
partx -u "${LAST_PART}"

# Do not fail resize2fs if no mtab entry is found, e.g.,
# when using systemd mount units.
export EXT2FS_NO_MTAB_OK=1

resize2fs "${LAST_PART}"
