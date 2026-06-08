#!/usr/bin/env bash
# This software is a part of ISAR.
# Copyright (C) Siemens AG, 2026
#
# SPDX-License-Identifier: MIT

#--------------------------------------------------------------------------
# sys_api.sh - Backend APIs for deploy-image-wic installer.
#
# This file intentionally contains only system/backend logic:
# - image discovery
# - target device discovery and filtering
# - low-level install/copy flow
#
# UI concerns (dialog boxes, menus, confirmations) are implemented in
# installer_ui.sh and called by the main orchestrator script.
#--------------------------------------------------------------------------

# Globals populated by sys_discover_target_devices().
SYS_CURRENT_ROOT_DEV=""
SYS_TARGET_DEVICES=()

#--------------------------------------------------------------------------
# sys_first_default_image_name <install_data_dir>
#
# Returns:
#   basename of matching *.wic* image (excluding *.wic.bmap), or empty.
#--------------------------------------------------------------------------
sys_first_default_image_name() {
    local install_data_dir="$1"

    find "$install_data_dir" -type f -iname "*.wic*" -a -not -iname "*.wic.bmap" \
        -exec basename {} \; | head -n 1
}

#--------------------------------------------------------------------------
# sys_list_installable_entries <install_data_dir>
#
# Returns:
#   relative file paths under install_data_dir, one per line.
#   Files ending in *.wic.bmap are excluded.
#--------------------------------------------------------------------------
sys_list_installable_entries() {
    local install_data_dir="$1"

    (
        cd "$install_data_dir" || return 1
        find . -type f ! -iname "*.wic.bmap" -print | sed 's#^./##'
    )
}

#--------------------------------------------------------------------------
# sys_resolve_image_path <install_data_dir> <image_or_path>
#
# Arguments:
#   install_data_dir - base directory where installable images are stored
#   image_or_path - either a relative image filename under install_data_dir
#                   or an explicit absolute/relative filesystem path
#
# Returns:
#   absolute image path if resolvable, else non-zero return code.
#--------------------------------------------------------------------------
sys_resolve_image_path() {
    local install_data_dir="$1"
    local image_or_path="$2"

    if [ -f "$image_or_path" ]; then
        echo "$image_or_path"
        return 0
    fi

    if [ -f "$install_data_dir/$image_or_path" ]; then
        echo "$install_data_dir/$image_or_path"
        return 0
    fi

    return 1
}

#--------------------------------------------------------------------------
# sys_discover_target_devices
#
# Populates globals:
#   SYS_CURRENT_ROOT_DEV - current live root device identifier
#   SYS_TARGET_DEVICES   - array with valid target block devices (/dev/*)
#
# Filtering rules match legacy deploy-image-wic behavior, including:
# - skip installer/live root device and backing devices
# - skip loop/dm/ram/sr/mtd/zram
# - skip inactive md arrays and md members
#--------------------------------------------------------------------------
sys_discover_target_devices() {
    local current_root_dev_type
    local current_root_dev
    local root_source
    local root_source_resolved
    local base_no_part
    local slave
    local slave_dev
    local slave_base
    local devices
    local mmc_devices
    local device
    local is_raid_member
    local holder_path
    local holder_name
    local state
    local skip_device
    local ex

    local exclude_list=()

    SYS_TARGET_DEVICES=()

    # Determine the live root device so we do not offer the current system disk
    # as an install target. For NFS roots use a special sentinel value.

    current_root_dev_type=$(findmnt / -o fstype -n)
    if [ "$current_root_dev_type" = "nfs" ]; then
        current_root_dev="nfs"
        exclude_list+=("nfs")
    else
        root_source=$(findmnt / -o source -n)
        root_source_resolved=$(readlink -f "$root_source" 2>/dev/null || echo "$root_source")
        current_root_dev=${root_source_resolved#/dev/}

        exclude_list+=("$current_root_dev")

        # Strip partition suffix for common disk names so the base device
        # (e.g. /dev/sda or /dev/mmcblk0) also does not become selectable.
        if [[ "$current_root_dev" =~ ^(mmcblk|nvme) ]]; then
            base_no_part="${current_root_dev%p[0-9]*}"
        else
            base_no_part="${current_root_dev%%[0-9]*}"
        fi

        if [ -n "$base_no_part" ]; then
            exclude_list+=("$base_no_part")
        fi

        # Exclude backing devices for the live root, such as multipath or RAID
        # underlying devices exposed via /sys/block/<root>/slaves.
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

    SYS_CURRENT_ROOT_DEV="$current_root_dev"

    # Gather block devices from /sys/block while preserving mmcblk devices that
    # would otherwise be filtered by the main find expression.
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
            # Skip RAID member devices, because we only want whole block devices
            # available for standalone image installation.
            continue
        fi

        if [[ "$device" == md* ]]; then
            # Accept only active or clean md arrays, reject degraded/inactive RAID sets.
            if [ -f "/sys/block/$device/md/array_state" ]; then
                state=$(cat /sys/block/$device/md/array_state | tr -d '\n' | tr -d ' ')
                if [ "$state" != "active" ] && [ "$state" != "clean" ]; then
                    echo "Skipping RAID device $device: state='$state'" >&2
                    continue
                fi
                echo "Found RAID device $device: state='$state'" >&2
            else
                echo "Skipping RAID device $device: no array_state file" >&2
                continue
            fi
        fi

        case "$device" in
            dm-*|loop*|mtd*|sr*|ram*|zram*)
                continue
                ;;
        esac

        skip_device=0
        for ex in "${exclude_list[@]}"; do
            if [[ "$device" == "$ex"* ]]; then
                skip_device=1
                break
            fi
        done

        if [ "$skip_device" -eq 0 ]; then
            SYS_TARGET_DEVICES+=("/dev/$device")
        fi
    done
}

#--------------------------------------------------------------------------
# sys_device_size <device>
#
# Returns:
#   human-readable size string from lsblk, or empty if unavailable.
#--------------------------------------------------------------------------
sys_device_size() {
    local device="$1"
    lsblk --nodeps --noheadings -o SIZE "$device" 2>/dev/null | tr -d " "
}

#--------------------------------------------------------------------------
# sys_device_is_empty <device>
#
# Returns:
#   0 when first 1 MiB is zero-filled, 1 otherwise.
#--------------------------------------------------------------------------
sys_device_is_empty() {
    local device="$1"
    cmp /dev/zero "$device" -n 1M >/dev/null 2>&1
}

#--------------------------------------------------------------------------
# sys_version_ge <current> <required>
#
# Returns:
#   0 if current >= required, else 1.
#--------------------------------------------------------------------------
sys_version_ge() {
    local current="$1"
    local required="$2"

    if [ "$(printf '%s\n' "$current"X "$required" | sort -V | head -n 1)" != "$current"X ]; then
        return 0
    fi
    return 1
}

#--------------------------------------------------------------------------
# sys_bmap_options_for_image <image_path>
#
# Returns:
#   bmaptool options string ("--nobmap" when no sidecar bmap is present).
#--------------------------------------------------------------------------
sys_bmap_options_for_image() {
    local image_path="$1"
    local disk_bmap

    disk_bmap="${image_path%.wic*}.wic.bmap"
    if [ -f "$disk_bmap" ]; then
        # If a .wic.bmap sidecar exists, return an empty option string so
        # bmaptool uses the bundled map automatically.
        echo ""
    else
        echo "--nobmap"
    fi
}

#--------------------------------------------------------------------------
# sys_install_image_with_lock <image_path> <target_device>
#
# Performs the actual bmaptool copy, serializing concurrent installer
# consoles via flock. When UI hook functions are available, this API
# uses them to present a progress gauge in attended mode.
#
# Optional UI hooks (if defined):
#   ui_start_progress_gauge <pipe_path>
#   ui_stop_progress_gauge
#--------------------------------------------------------------------------
sys_install_image_with_lock() {
    local image_path="$1"
    local target_device="$2"
    local lockfile="/run/installer.lock"
    local progress_pipe="/run/installer.fifo"
    local bmap_options
    local bmap_version
    local quiet_flag=""

    bmap_options=$(sys_bmap_options_for_image "$image_path")

    exec 9>"$lockfile"
    if flock -n 9; then
        bmap_version=$(bmaptool --version | awk '{ print $NF }')

        if sys_version_ge "$bmap_version" "3.6"; then
            if [ -p "$progress_pipe" ]; then
                rm -f "$progress_pipe"
            fi

            if ! mkfifo "$progress_pipe"; then
                echo "Error: Failed to create named pipe $progress_pipe"
                return 1
            fi

            bmap_options="$bmap_options --psplash-pipe=$progress_pipe"
            quiet_flag="-q"

            if declare -F ui_start_progress_gauge >/dev/null; then
                ui_start_progress_gauge "$progress_pipe"
            fi
        fi

        # Run the actual copying step under the lock to avoid concurrent writes
        # from multiple installer consoles or sessions.
        if ! bmaptool $quiet_flag copy $bmap_options "$image_path" "$target_device"; then
            if declare -F ui_stop_progress_gauge >/dev/null; then
                ui_stop_progress_gauge
            fi
            return 1
        fi

        if declare -F ui_stop_progress_gauge >/dev/null; then
            ui_stop_progress_gauge
        fi
    else
        echo "Installation already running in another console."
        sleep 5

        if [ -e "$progress_pipe" ]; then
            echo "Installation progress..."
            tail -f "$progress_pipe" | while read -r line; do
                printf "\r%s%%" "$line"
            done
        else
            echo "Waiting for installation to finish..."
            while pgrep -x "bmaptool" >/dev/null; do
                sleep 5
            done
        fi
    fi

    return 0
}
