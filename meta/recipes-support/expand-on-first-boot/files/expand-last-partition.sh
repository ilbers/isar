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
ROOT_DEV_NAME=${ROOT_DEV##*/}
ROOT_DEV_SLAVE=$(find /sys/block/"${ROOT_DEV_NAME}"/slaves -mindepth 1 -print -quit 2>/dev/null || true)
if [ -n "${ROOT_DEV_SLAVE}" ]; then
	ROOT_DEV=/dev/${ROOT_DEV_SLAVE##*/}
fi

BOOT_DEV="$(echo "${ROOT_DEV}" | sed 's/p\?[0-9]*$//')"
if [ "${ROOT_DEV}" = "${BOOT_DEV}" ]; then
	echo "Boot device equals root device - no partitioning found" >&2
	exit 1
fi

# this value is in blocks. Normally a block has 512 bytes.
BUFFER_SIZE=32768
BOOT_DEV_NAME=${BOOT_DEV##*/}
DISK_SIZE="$(cat /sys/class/block/"${BOOT_DEV_NAME}"/size)"
ALL_PARTS_SIZE=0
for PARTITION in /sys/class/block/"${BOOT_DEV_NAME}"/"${BOOT_DEV_NAME}"*; do
	PART_SIZE=$(cat "${PARTITION}"/size)
	ALL_PARTS_SIZE=$((ALL_PARTS_SIZE + PART_SIZE))
done

MINIMAL_SIZE=$((ALL_PARTS_SIZE + BUFFER_SIZE))
if [ "$DISK_SIZE" -lt "$MINIMAL_SIZE" ]; then
	echo "Disk is practically already full, doing nothing." >&2
	exit 0
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
