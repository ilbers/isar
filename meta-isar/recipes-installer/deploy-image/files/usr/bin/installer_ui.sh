#!/usr/bin/env bash
#
# installer_ui.sh — Attended installer frontend
# ------------------------------------------------

SCRIPT_DIR="$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)"
INSTALL_DATA=${INSTALL_DATA:-./install}

# Backend APIs
. "$SCRIPT_DIR/sys_api.sh"

# ------------------------------------------------
# Helpers
# ------------------------------------------------
die() {
    dialog --msgbox "$1" 6 60
    exit 1
}

# ------------------------------------------------
# UI: Select image
# ------------------------------------------------
ui_select_image() {
    local images json list=()

    # On failure, show error dialog and exit
    json=$(sys_locate_disk_images search_path="$INSTALL_DATA") || \
        die "No installable images found in $INSTALL_DATA"

    # Extract image paths from JSON
    images=$(echo "$json" | sed -n 's/.*"images":\[\(.*\)\].*/\1/p' | tr -d '"' | tr ',' '\n')

    # Building dialog menu entries
    for img in $images; do
        base=$(basename "$img")
        list+=("$img" "$base")
    done

    # Display menu and capture selection
    INSTALL_IMAGE=$(dialog --no-tags \
        --menu "Select image to install" 10 70 5 \
        "${list[@]}" \
        --output-fd 1) || exit 0
}

# ------------------------------------------------
# UI: Select target device
# ------------------------------------------------
ui_select_target_device() {
    local list=()

    devices=$(sys_list_valid_target_devices) || \
        die "No valid target devices found"

    for dev in $devices; do
        [ -b "$dev" ] || continue

        size=$(lsblk --nodeps --noheadings -o SIZE "$dev" 2>/dev/null | tr -d " ")
        [ -z "$size" ] && size="unknown"

        if cmp /dev/zero "$dev" -n 1M >/dev/null 2>&1; then
            state="empty"
        else
            state="contains data"
        fi

        list+=("$dev" "$dev ($size, $state)")
    done

    if [ "${#list[@]}" -lt 2 ]; then
        die "no installable target devices available"
    fi

    TARGET_DEVICE=$(dialog --no-tags \
        --menu "Select target device" 10 70 6 \
        "${list[@]}" \
        --output-fd 1) || exit 0
}

run_interactive_installer() {
    clear
    ui_select_image
    ui_select_target_device
}

run_interactive_installer
