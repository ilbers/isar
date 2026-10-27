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
                if [ "$state" != "active" ] && [ "$state" != "clean" ] && [ "$state" != "read-auto" ]; then
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
# sys_luks_list_volumes <target_device>
#
# Prints the LUKS2 volumes found on target_device (and its partitions),
# one per line, once the target has been verified to be offline and every
# volume to be a pristine provisioning container: a single keyslot, no
# tokens and no pending reencryption. Unencrypted targets yield no output
# and need neither cryptsetup nor jq; encrypted ones yield no output (with a
# warning) when either is missing, so that key rotation is skipped.
#
# Returns:
#   0 on success (also when tools are missing, see above), 1 when the
#   target is busy or a volume is unsupported (reason on stderr).
#--------------------------------------------------------------------------
sys_luks_list_volumes() {
    local target_device="$1"
    local devices device mounts fstype metadata probe_status
    local holders
    local volumes=()

    partprobe "$target_device" || true
    ! command -v udevadm >/dev/null || udevadm settle || true

    devices=$(lsblk --list --noheadings --paths --output NAME "$target_device") || return 1
    while IFS= read -r device; do
        mounts=$(lsblk --nodeps --noheadings --output MOUNTPOINTS "$device")
        if [ -n "${mounts//[[:space:]]/}" ]; then
            echo "Error: $device is mounted" >&2
            return 1
        fi
        holders=(/sys/class/block/"${device##*/}"/holders/*)
        if [ -e "${holders[0]}" ]; then
            echo "Error: $device has active holders" >&2
            return 1
        fi

        probe_status=0
        fstype=$(blkid --probe --output value --match-tag TYPE "$device" 2>/dev/null) || probe_status=$?
        if [ "$probe_status" != 0 ] && [ "$probe_status" != 2 ]; then
            echo "Error: cannot probe $device" >&2
            return 1
        fi
        [ "$fstype" = crypto_LUKS ] || continue

        # Optional tools: without them keys are not rotated (see sys_luks_rotate_keys).
        if ! command -v cryptsetup >/dev/null || ! command -v jq >/dev/null; then
            echo "Warning: $device is encrypted but cryptsetup/jq are missing, skipping key rotation" >&2
            return 0
        fi
        if ! cryptsetup isLuks --type luks2 "$device"; then
            echo "Error: $device is not a LUKS2 volume" >&2
            return 1
        fi
        metadata=$(cryptsetup luksDump --dump-json-metadata "$device") || return 1
        if ! jq -e '
                (.tokens | length) == 0 and
                (.keyslots | length) == 1 and
                all(.keyslots[]; .type == "luks2") and
                (.segments | length) == 1 and
                all(.segments[]; .type == "crypt" and ((.flags // []) | length) == 0)
            ' <<< "$metadata" >/dev/null; then
            echo "Error: unsupported or interrupted LUKS state on $device" >&2
            return 1
        fi
        volumes+=("$device")
    done <<< "$devices"

    [ ${#volumes[@]} -eq 0 ] || printf '%s\n' "${volumes[@]}"
}

#--------------------------------------------------------------------------
# sys_luks_make_keyfile <device>
#
# Creates a private key file holding the initial passphrase of <device> and
# prints its path. The passphrase is empty unless the optional hook
# sys_luks_passphrase_hook is defined; it is called with the device and
# must print the passphrase on stdout (no trailing newline is added).
#--------------------------------------------------------------------------
sys_luks_make_keyfile() {
    local device="$1"
    local keyfile passphrase=""

    if declare -F sys_luks_passphrase_hook >/dev/null; then
        passphrase=$(sys_luks_passphrase_hook "$device") || return 1
    fi
    keyfile=$(mktemp /run/installer-luks-key.XXXXXX) || return 1
    printf '%s' "$passphrase" > "$keyfile" || { rm -f -- "$keyfile"; return 1; }
    echo "$keyfile"
}

#--------------------------------------------------------------------------
# sys_luks_reencrypt_volume <device>
#
# Generates a new volume key for a provisioning LUKS2 volume, unlocking it
# with its initial passphrase (see sys_luks_make_keyfile), and emits one
# integer percentage per line on stdout so callers can drive a progress
# indicator. The volume is offline and a failed run requires reinstalling,
# so no resilience journal is kept (this halves the amount of data written).
#
# Returns:
#   0 when the volume was reencrypted and verified, 1 otherwise.
#--------------------------------------------------------------------------
sys_luks_reencrypt_volume() {
    local device="$1"
    local keyfile log uuid metadata status

    keyfile=$(sys_luks_make_keyfile "$device") || return 1
    uuid=$(cryptsetup luksUUID "$device") || { rm -f -- "$keyfile"; return 1; }
    log=$(mktemp /run/installer-luks-reencrypt.XXXXXX) || { rm -f -- "$keyfile"; return 1; }

    # Progress is printed on stdout, errors on stderr (kept for reporting).
    cryptsetup reencrypt --batch-mode --force-offline-reencrypt \
        --resilience none --progress-json --progress-frequency 1 \
        --key-file "$keyfile" "$device" 2> "$log" |
        jq -R --unbuffered -r '
            fromjson? | select(.device_size != null) |
            (((.device_bytes | tonumber) * 100) / (.device_size | tonumber) | floor)'
    status=${PIPESTATUS[0]}
    [ "$status" = 0 ] || cat "$log" >&2
    rm -f -- "$log"

    if [ "$status" = 0 ]; then
        [ "$(cryptsetup luksUUID "$device")" = "$uuid" ] || status=1
    fi
    if [ "$status" = 0 ]; then
        cryptsetup open --test-passphrase --key-file "$keyfile" "$device" || status=1
    fi
    if [ "$status" = 0 ]; then
        metadata=$(cryptsetup luksDump --dump-json-metadata "$device") || status=1
        jq -e 'all(.keyslots[]; .type != "reencrypt") and
            all(.segments[]; .type == "crypt" and ((.flags // []) | length) == 0)' \
            <<< "$metadata" >/dev/null || status=1
    fi

    rm -f -- "$keyfile"
    [ "$status" = 0 ] || echo "Error: reencryption of $device failed" >&2
    [ "$status" = 0 ]
}

#--------------------------------------------------------------------------
# sys_luks_rotate_keys <target_device>
#
# Installed images share the volume keys of the image they were built
# from. Reencrypt every LUKS2 volume of target_device so the installed
# system uses its own master keys. Must run while the target is offline.
#
# Optional hooks (if defined):
#   sys_luks_passphrase_hook <device>
#     prints the initial passphrase of <device> (default: empty)
#   ui_reencrypt_volume_gauge <device> <index> <count>
#     reads percentages from stdin while a volume is reencrypted
#
# Returns:
#   0 when all volumes were rotated, none are encrypted, or rotation was
#   skipped because cryptsetup or jq is missing (warning on stderr);
#   1 otherwise. On failure the target must not be booted and must be
#   reinstalled.
#--------------------------------------------------------------------------
sys_luks_rotate_keys() {
    local target_device="$1"
    local volumes=()
    local device keyfile listing status index=0 count

    listing=$(sys_luks_list_volumes "$target_device") || return 1
    [ -n "$listing" ] || return 0
    mapfile -t volumes <<< "$listing"
    count=${#volumes[@]}

    # Fail before touching any volume when the initial credential is wrong.
    for device in "${volumes[@]}"; do
        keyfile=$(sys_luks_make_keyfile "$device") || return 1
        if ! cryptsetup open --test-passphrase --key-file "$keyfile" "$device"; then
            echo "Error: initial unlock credential is unavailable for $device" >&2
            rm -f -- "$keyfile"
            return 1
        fi
        rm -f -- "$keyfile"
    done

    for device in "${volumes[@]}"; do
        index=$((index + 1))
        if declare -F ui_reencrypt_volume_gauge >/dev/null; then
            sys_luks_reencrypt_volume "$device" | ui_reencrypt_volume_gauge "$device" "$index" "$count"
            status=${PIPESTATUS[0]}
        else
            echo "Reencrypting $device ($index/$count); do not power off."
            sys_luks_reencrypt_volume "$device" | while read -r percent; do
                printf '\r%s: %s%%' "$device" "$percent"
            done
            status=${PIPESTATUS[0]}
            echo
        fi
        [ "$status" = 0 ] || return 1
    done
}

#--------------------------------------------------------------------------
# sys_install_image_with_lock <image_path> <target_device>
#
# Performs the actual bmaptool copy, serializing concurrent installer
# consoles via flock, then rotates the LUKS volume keys of the target
# (see sys_luks_rotate_keys) before the lock is released. When UI hook
# functions are available, this API uses them to present progress gauges
# in attended mode.
#
# Optional UI hooks (if defined):
#   ui_start_progress_gauge <pipe_path>
#   ui_stop_progress_gauge
#   ui_reencrypt_volume_gauge <device> <index> <count>
#--------------------------------------------------------------------------
sys_install_image_with_lock() {
    local image_path="$1"
    local target_device="$2"
    local lockfile="/run/installer.lock"
    local progress_pipe="/run/installer.fifo"
    local result_file="/run/installer.result"
    local bmap_options
    local bmap_version
    local quiet_flag=""

    bmap_options=$(sys_bmap_options_for_image "$image_path")

    exec 9>"$lockfile"
    if flock -n 9; then
        rm -f "$result_file"
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
            echo failed > "$result_file"
            return 1
        fi

        if declare -F ui_stop_progress_gauge >/dev/null; then
            ui_stop_progress_gauge
        fi

        # Still under the lock: give the installed system its own volume keys.
        if ! sys_luks_rotate_keys "$target_device"; then
            echo "Volume-key rotation failed. Installation is incomplete; do not boot the target." >&2
            echo failed > "$result_file"
            return 1
        fi

        echo ok > "$result_file"
    else
        echo "Installation already running in another console. Waiting for it to finish..."
        flock 9
        # The other console owns the result; only report success if it did.
        [ "$(cat "$result_file" 2>/dev/null)" = ok ] || return 1
    fi

    return 0
}
