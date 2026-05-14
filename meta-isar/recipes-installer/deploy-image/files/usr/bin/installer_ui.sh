#!/usr/bin/env bash
# This software is a part of ISAR.
# Copyright (C) Siemens AG, 2026
#
# SPDX-License-Identifier: MIT

#--------------------------------------------------------------------------
# installer_ui.sh - Frontend/UI helpers for isar installer.
#
# This file is intentionally UI-only:
# - dialog menus and message boxes
# - attended confirmations
# - user abort countdown handling
#--------------------------------------------------------------------------
UI_GAUGE_PID=""

#--------------------------------------------------------------------------
# ui_show_error <message>
#
# Displays an error dialog in attended mode.
#--------------------------------------------------------------------------
ui_show_error() {
    local message="$1"
    dialog --msgbox "$message" 6 60
}

#--------------------------------------------------------------------------
# ui_show_info <message>
#
# Displays an informational dialog in attended mode.
#--------------------------------------------------------------------------
ui_show_info() {
    local message="$1"
    dialog --msgbox "$message" 6 60
}

#--------------------------------------------------------------------------
# ui_countdown_allow_attended_switch <seconds> <abort_file>
#
# In unattended mode, this gives users a chance to switch to attended
# mode by pressing any key. Returns 0 when attended mode should be
# used, and 1 otherwise.
#--------------------------------------------------------------------------
ui_countdown_allow_attended_switch() {
    local timeout="$1"
    local abort_file="$2"
    local i

    # Countdown loop prints a message once per second and accepts a key press.
    # If any key is pressed, create the abort trigger file for the caller.
    for ((i=timeout; i>0; i--)); do
        echo -ne "\rUnattended installation will start in $i seconds. Press any key to switch to attended mode..."

        if [ -f "$abort_file" ] || read -n 1 -t 1; then
            touch "$abort_file"
            echo
            return 0
        fi
    done

    echo
    return 1
}

#--------------------------------------------------------------------------
# ui_select_image_menu <install_data_dir>
#
# Uses sys_list_installable_entries backend API and returns selected
# relative image path on stdout.
#--------------------------------------------------------------------------
ui_select_image_menu() {
    local install_data_dir="$1"
    local list=()
    local entry
    local selected

    while IFS= read -r entry; do
        [ -n "$entry" ] || continue
        list+=("$entry" "$entry")
    done < <(sys_list_installable_entries "$install_data_dir")

    if [ "${#list[@]}" -eq 0 ]; then
        return 1
    fi

    selected=$(dialog --no-tags \
        --menu "Select image to be installed" 12 70 6 \
        "${list[@]}" --output-fd 1) || return 2

    echo "$selected"
    return 0
}

#--------------------------------------------------------------------------
# ui_select_target_device_menu <device...>
#
# Displays candidate target devices and returns selected /dev path.
#--------------------------------------------------------------------------
ui_select_target_device_menu() {
    local list=()
    local target
    local target_size
    local state
    local selected

    for target in "$@"; do
        [ -b "$target" ] || continue

        target_size=$(sys_device_size "$target")
        [ -n "$target_size" ] || target_size="unknown"

        # Indicate whether the selected device is already empty, to help users
        # avoid accidental overwrite of data.
        if sys_device_is_empty "$target"; then
            state="empty"
        else
            state="contains data"
        fi

        list+=("$target" "$target ($target_size, $state)")
    done

    if [ "${#list[@]}" -eq 0 ]; then
        return 1
    fi

    selected=$(dialog --no-tags \
        --menu "Select device to install image to" 12 70 6 \
        "${list[@]}" --output-fd 1) || return 2

    echo "$selected"
    return 0
}

#--------------------------------------------------------------------------
# ui_confirm_install <image_path> <target_device> <target_size>
#
# Returns:
#   0 when user confirms, 1 when canceled.
#--------------------------------------------------------------------------
ui_confirm_install() {
    local image_path="$1"
    local target_device="$2"
    local target_size="$3"

    dialog --yes-label Ok --no-label Cancel \
        --yesno "Start installing\n'$image_path'\nto $target_device (capacity: $target_size)" 8 70
}

#--------------------------------------------------------------------------
# ui_confirm_overwrite
#
# Returns:
#   0 when user accepts overwrite, 1 when canceled.
#--------------------------------------------------------------------------
ui_confirm_overwrite() {
    dialog --defaultno --yesno "WARNING: Target device is not empty! Continue anyway?" 8 70
}

#--------------------------------------------------------------------------
# ui_start_progress_gauge <pipe_path>
#
# Opens a dialog gauge and updates it from bmaptool psplash pipe.
#--------------------------------------------------------------------------
ui_start_progress_gauge() {
    local pipe_path="$1"

    (
        while true; do
            if read -r line < "$pipe_path"; then
                percentage=$(echo "$line" | awk '{ print $2 }')
                echo "$percentage"
            fi
        done
    ) | dialog --gauge "Flashing image, please wait..." 10 70 0 &

    UI_GAUGE_PID=$!
}

#--------------------------------------------------------------------------
# ui_stop_progress_gauge
#
# Best-effort termination of the active progress gauge process.
#--------------------------------------------------------------------------
ui_stop_progress_gauge() {
    if [ -n "$UI_GAUGE_PID" ]; then
        kill "$UI_GAUGE_PID" 2>/dev/null || true
        UI_GAUGE_PID=""
    fi
}

