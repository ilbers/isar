#!/usr/bin/env bash
# This software is a part of ISAR.
# Copyright (C) Siemens AG, 2024
#
# SPDX-License-Identifier: MIT

installdata=${INSTALL_DATA:-/install}

SCRIPT_DIR=$( dirname -- "$( readlink -f -- "$0"; )"; )

. "${SCRIPT_DIR}/../lib/deploy-image-wic/handle-config.sh"

if [ "$installer_unattended" = true ] && [ "$installer_unattended_abort_enable" = true ]; then
    abort_file=/tmp/attended_mode_trigger
    for ((i=$installer_unattended_abort_timeout; i>0; i--)); do
        echo -ne "\rUnattended installation will start in $i seconds. Press any key to switch to attended mode..."

	# Switch to attended mode if the abort file exists or any key pressed during countdown
	# Create abort file to notify all other console instances to abort
        if [ -f "$abort_file" ] || read -n 1 -t 1; then
            installer_unattended=false
            touch "$abort_file"
            break
        fi
    done
fi

if ! $installer_unattended; then
    installer_image_uri=$(find "$installdata" -type f -iname "*.wic*" -a -not -iname "*.wic.bmap" -exec basename {} \;)
    if [ -z "$installer_image_uri" ] || [ ! -f "$installdata/$installer_image_uri" ]; then
        pushd "$installdata"
        for f in $(find . -type f ! -iname "*.wic.bmap"); do
            array+=("$f" "$f")
        done
        popd
        if [ ${#array[@]} -gt 0 ]; then
            if ! installer_image_uri=$(dialog --no-tags \
                              --menu "Select image to be installed" 10 60 3 \
                              "${array[@]}" --output-fd 1); then
                exit 0
            fi
        fi
    fi

    if [ ! -f "$installdata/$installer_image_uri" ]; then
        dialog --msgbox "Could not find an image to install. Installation aborted." 6 60
        exit 1
    fi

    # inspired by poky/meta/recipes-core/initrdscripts/files/install-efi.sh
    target_device_list=""
    current_root_dev_type=$(findmnt / -o fstype -n)
    exclude_list=()

    if [ "$current_root_dev_type" = "nfs" ]; then
        current_root_dev="nfs"
        exclude_list+=("nfs")
    else
    # For normal or immutable systems, get the backing device of '/'
        root_source=$(findmnt / -o source -n)
        root_source_resolved=$(readlink -f "$root_source" 2>/dev/null || echo "$root_source")
        current_root_dev=${root_source_resolved#/dev/}

        # Always exclude the exact device mounted as /
        exclude_list+=("$current_root_dev")

        base_no_part=${current_root_dev%%[0-9]*}
        if [ -n "$base_no_part" ]; then
            exclude_list+=("$base_no_part")
        fi

        # If root is coming through a dm-* device (e.g., dm-verity),
        # the actual physical devices appear under /sys/block/<dm>/slaves/.
        # We must exclude those slaves as well, otherwise the installer
        # might show the live USB stick as a valid target.
        if [ -d "/sys/block/$current_root_dev/slaves" ]; then
            for slave in /sys/block/"$current_root_dev"/slaves/*; do
                [ -e "$slave" ] || continue
                slave_dev=$(basename "$slave")
                exclude_list+=("$slave_dev")
                slave_base=${slave_dev%%[0-9]*}
                [ -n "$slave_base" ] && exclude_list+=("$slave_base")
            done
        fi
    fi

    echo "Searching for target device..."

    devices=$(find /sys/block/ -type b,c,f,l -not -iname "mmcblk*" -printf "%f\n") || true
    mmc_devices=$(find /sys/block/ -type b,c,f,l -iname "mmcblk[0-9]" -printf "%f\n") || true
    devices="$devices $mmc_devices"

    for device in $devices; do
        is_raid_member=0

        if [ -d "/sys/block/$device/holders" ] && [ ! -d "/sys/block/$device/md" ]; then
            for holder_path in /sys/block/$device/holders/*; do
                holder_name=$(basename "$holder_path")
                case "$holder_name" in
                    md[0-9]*)
                        is_raid_member=1
                        break
                        ;;
                esac
            done
        fi

        if [ "$is_raid_member" -eq 1 ]; then
            continue # Skip RAID member disks
        fi

        if [[ "$device" == md* ]]; then
            if [ -f "/sys/block/$device/md/array_state" ]; then
                state=$(cat /sys/block/$device/md/array_state)
                if [ "$state" != "active" ] && [ "$state" != "clean" ]; then
                    continue
                fi
            else
                continue
            fi
        fi

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
                #skip any excluded devices (root and its slaves)
                skip_device=0
                for ex in "${exclude_list[@]}"; do
                    if [[ "$device" == "$ex"* ]]; then
                        skip_device=1
                        break
                    fi
                done

                if [ "$skip_device" -eq 0 ]; then
                    target_device_list="$target_device_list $device"
                fi
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
        if ! installer_target_dev=$(dialog --no-tags \
                             --menu "Select device to install image to" 10 60 3 \
                             "${array[@]}" --output-fd 1); then
            exit 0
        fi
    else
        installer_target_dev="/dev/$(echo "$target_device_list" | tr -d " ")"
    fi
    TARGET_DEVICE_SIZE=$(lsblk --nodeps --noheadings -o SIZE "$installer_target_dev" | tr -d " ")
    if ! dialog --yes-label Ok --no-label Cancel \
                --yesno "Start installing\n'$installer_image_uri'\nto $installer_target_dev (capacity: $TARGET_DEVICE_SIZE)" 7 60; then
        exit 0
    fi

    # set absolute paths to be compatible with unattended mode
    installer_image_uri="$installdata/$installer_image_uri"
fi

if ! cmp /dev/zero "$installer_target_dev" -n 1M; then
    if ! $installer_unattended; then
        if ! dialog --defaultno \
                    --yesno "WARNING: Target device is not empty! Continue anyway?" 5 60; then
            exit 0
        fi
    else
        if [ "$installer_target_overwrite" != "OVERWRITE" ]; then
            echo "Target device is not empty! -> Abort"
            echo "If you want to override existing data set \"installer.target.overwrite=OVERWRITE\" on your kernel cmdline or edit your \"auto.install\" file accordingly."

            exit 1
        fi
    fi
fi

bmap_options=""

# bmap file is expected to be next to the installer image
DISK_BMAP="${installer_image_uri%.wic*}.wic.bmap"

if [ ! -f "$DISK_BMAP" ]; then
    bmap_options="--nobmap"
fi

if ! $installer_unattended; then
    clear
fi

# Function to compare version numbers
version_ge() {
    if [ "$(printf '%s\n' "$1"X "$2" | sort -V | head -n 1)" != "$1"X ]; then
        return 0
    else
        return 1
    fi
}

if ! $installer_unattended; then
    # Get bmap-tools version
    bmap_version=$(bmaptool --version | awk '{ print $NF }')

    if version_ge "$bmap_version" "3.6"; then
        # Create a named pipe for progress communication
        progress_pipe="/tmp/progress"
        if ! mkfifo "$progress_pipe"; then
            echo "Error: Failed to create named pipe $progress_pipe"
            exit 1
        fi

        # Add psplash pipe to bmap_options
        bmap_options="$bmap_options --psplash-pipe=$progress_pipe"
        quiet_flag="-q"

        # Initialize the dialog gauge and update it dynamically
        (
            while true; do
                if read -r line < "$progress_pipe"; then
                    percentage=$(echo "$line" | awk '{ print $2 }')
                    echo "$percentage"
                fi
            done
        ) | dialog --gauge "Flashing image, please wait..." 10 70 0 &

        gauge_pid=$!
    fi
fi

if ! bmaptool $quiet_flag copy $bmap_options "$installer_image_uri" "$installer_target_dev"; then
    kill "$gauge_pid"
    exit 1
fi

# Attempt to terminate the gauge process if still running.
# Errors are ignored since the process may already have exited.
kill "$gauge_pid" 2>/dev/null

if ! $installer_unattended; then
    dialog --title "Reboot" \
           --msgbox "Installation was successful. System will be rebooted. Please remove the USB stick." 6 60
else
    echo "Installation was successful."
fi

exit 0
