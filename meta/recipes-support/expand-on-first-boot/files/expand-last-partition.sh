#!/bin/sh
#
# Resize last partition to full medium size
#
# This software is a part of ISAR.
# Copyright (c) Siemens AG, 2018-2022
#
# SPDX-License-Identifier: MIT

set -e

ROOT_DEV="$(readlink -f "$(findmnt / -o source -n)")"
ROOT_DEV_NAME=${ROOT_DEV##*/}
ROOT_DEV_SLAVE=$(find /sys/block/"${ROOT_DEV_NAME}"/slaves -mindepth 1 -print -quit 2>/dev/null || true)
while [ -d "${ROOT_DEV_SLAVE}/slaves" ]; do
	ROOT_DEV_SLAVE=$(find "${ROOT_DEV_SLAVE}"/slaves -mindepth 1 -print -quit 2>/dev/null || true)
done
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

IS_GPT="$(sfdisk -d "${BOOT_DEV}" 2>/dev/null | grep -q "label: gpt" && echo 1)"
if [ "$IS_GPT" = "1" ]; then
	dd if="${BOOT_DEV}" of=/dev/shm/__mbr__.bak count=1
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

if [ "$IS_GPT" = "1" ]; then
	dd if=/dev/shm/__mbr__.bak of="${BOOT_DEV}"
	rm /dev/shm/__mbr__.bak
fi

# Inform the kernel about the partitioning change
partx -u "${LAST_PART}"

if grep -q x-systemd.growfs /etc/fstab; then
	echo "Found x-systemd.growfs option in /etc/fstab, won't grow." >&2
	exit 0
fi

# some filesystems need to be mounted i.e. btrfs, but mounting also helps
# detect the filesystem type without having to wait for udev
# mount $LAST_PART out of tree, so we won't conflict with other mounts
ret=0
# Determine the filesystem type and perform the appropriate resize function
FS_TYPE=$(blkid --output value --match-tag TYPE "${LAST_PART}" )
MOUNT_POINT=$(mktemp -d -p "" "$(basename "$0").XXXXXXXXXX")
if [ "$FS_TYPE" = "crypto_LUKS" ]; then
	if [ ! -x /usr/sbin/cryptsetup ]; then
		echo "'cryptsetup' is missing cannot resize last partition as it is from type 'crypto_LUKS'"
		exit 1
	fi
	last_part_device_name=${LAST_PART#\/dev/}

	mapping_name=$(cat /sys/class/block/"$last_part_device_name"/holders/*/dm/name)
	cryptsetup resize "$mapping_name"
	mount /dev/mapper/"$mapping_name" "${MOUNT_POINT}"
	FS_TYPE=$(findmnt -fno FSTYPE "${MOUNT_POINT}" )
	LAST_PART=/dev/mapper/"$mapping_name"
else
	mount "${LAST_PART}" "${MOUNT_POINT}"
fi
case ${FS_TYPE} in
ext*)

	# Do not fail resize2fs if no mtab entry is found, e.g.,
	# when using systemd mount units.
	export EXT2FS_NO_MTAB_OK=1
	resize2fs "${LAST_PART}"
	;;
btrfs)
	btrfs filesystem resize max "${MOUNT_POINT}"
	;;
*)
	echo "Unrecognized filesystem type ${FS_TYPE} - no resize performed"
	ret=1
	;;
esac

umount "${MOUNT_POINT}"
rmdir "${MOUNT_POINT}"
exit $ret
