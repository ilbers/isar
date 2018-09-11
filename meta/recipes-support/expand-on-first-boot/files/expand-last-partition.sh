#!/bin/sh
#
# Resize last partition to full medium size
#
# This software is a part of ISAR.
# Copyright (c) Siemens AG, 2018
#
# SPDX-License-Identifier: MIT

set -e

ROOT_DEV=$(findmnt / -o source -n)
BOOT_DEV=$(echo ${ROOT_DEV} | sed 's/p\?[0-9]*$//')

if [ "${ROOT_DEV}" = "${BOOT_DEV}" ]; then
	echo "Boot device equals root device - no partitioning found" >&2
	exit 1
fi

LAST_PART=$(sfdisk -d ${BOOT_DEV} 2>/dev/null | tail -1 | cut -d ' ' -f 1)

# Remove all hints to the current medium (last-lba) and last partition size,
# then ask sfdisk to recreate the partitioning
sfdisk -d ${BOOT_DEV} 2>/dev/null | grep -v last-lba | \
	sed 's|\('${LAST_PART}' .*, \)size=[^,]*, |\1|' | \
	sfdisk --force ${BOOT_DEV}

# Inform the kernel about the partitioning change
partx -u ${LAST_PART}

resize2fs ${LAST_PART}
