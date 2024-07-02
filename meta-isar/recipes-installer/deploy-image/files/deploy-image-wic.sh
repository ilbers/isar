#!/usr/bin/env bash
# This software is a part of ISAR.
# Copyright (C) Siemens AG, 2024
#
# SPDX-License-Identifier: MIT

installdata=${INSTALL_DATA:-/install}

DISK_IMAGE=$(find "$installdata" -type f -iname "*.wic*" -a -not -iname "*.wic.bmap" -exec basename {} \;)
if [ -z "$DISK_IMAGE" ] || [ ! -f "$installdata/$DISK_IMAGE" ]; then
    pushd "$installdata"
    for f in $(find . -type f); do
        array+=("$f" "$f")
    done
    popd
    if [ ${#array[@]} -gt 0 ]; then
        if ! DISK_IMAGE=$(dialog --no-tags \
                          --menu "Select image to be installed" 10 60 3 \
                          "${array[@]}" --output-fd 1); then
            exit 0
        fi
    fi
fi
if [ ! -f "$installdata/$DISK_IMAGE" ]; then
    dialog --msgbox "Could not find an image to install. Installation aborted." 6 60
    exit 1
fi
DISK_BMAP=$(find "$installdata" -type f -iname "${DISK_IMAGE%.wic*}.wic.bmap")
# inspired by poky/meta/recipes-core/initrdscripts/files/install-efi.sh

target_device_list=""
current_root_dev=$(readlink -f "$(findmnt / -o source -n)")
current_root_dev=${current_root_dev#\/dev/}
case $current_root_dev in
    mmcblk*)
        ;;
    nvme*)
        ;;
    *)
        current_root_dev=${current_root_dev%%[0-9]*}
        ;;
esac

echo "Searching for target device..."

devices=$(find /sys/block/ -type b,c,f,l -not -iname "mmcblk*" -printf "%f\n") || true
mmc_devices=$(find /sys/block/ -type b,c,f,l -iname "mmcblk[0-9]" -printf "%f\n") || true
devices="$devices $mmc_devices"

for device in $devices; do
    case $device in
        loop*)
            # skip loop device
            ;;
        mtd*)
            ;;
        sr*)
            # skip CDROM device
            ;;
        ram*)
            # skip ram device
            ;;
        *)
            case $device in
                $current_root_dev*)
                # skip the device we are running from
                ;;
                *)
                    target_device_list="$target_device_list $device"
                ;;
            esac
            ;;
    esac
done

if [ -z "${target_device_list}" ]; then
    dialog --msgbox "You need another device (besides the live device /dev/${current_root_dev}) to install the image. Installation aborted." 7 60
    exit 1
fi

if [ "$(echo "$target_device_list" | wc -w)" -gt 1 ]; then
    array=()
    for target in $(echo "$target_device_list" | xargs -n1 | sort); do
        target_size=$(lsblk --nodeps --noheadings -o SIZE /dev/"$target" | tr -d " ")
        if cmp /dev/zero /dev/"$target" -n 1M; then
            state="empty"
        else
            state="contains data"
        fi
        array+=("/dev/$target" "/dev/$target ($target_size, $state)")
    done
    if ! TARGET_DEVICE=$(dialog --no-tags \
                         --menu "Select device to install image to" 10 60 3 \
                         "${array[@]}" --output-fd 1); then
        exit 0
    fi
else
    TARGET_DEVICE=/dev/$(echo "$target_device_list" | tr -d " ")
fi
TARGET_DEVICE_SIZE=$(lsblk --nodeps --noheadings -o SIZE "$TARGET_DEVICE" | tr -d " ")
if ! dialog --yes-label Ok --no-label Cancel \
            --yesno "Start installing\n'$DISK_IMAGE'\nto $TARGET_DEVICE (capacity: $TARGET_DEVICE_SIZE)" 7 60; then
    exit 0
fi

if ! cmp /dev/zero "$TARGET_DEVICE" -n 1M && \
   ! dialog --defaultno \
            --yesno "WARNING: Target device is not empty! Continue anyway?" 5 60; then
    exit 0
fi

bmap_options=""
if [ -z "$DISK_BMAP" ]; then
    bmap_options="--nobmap"
fi
clear
if ! bmaptool copy ${bmap_options} "$installdata/$DISK_IMAGE" "${TARGET_DEVICE}"; then
    exit 1
fi

dialog --title "Reboot" \
       --msgbox "Installation is successful. System will be rebooted. Please remove the USB stick." 6 60
exit 0
