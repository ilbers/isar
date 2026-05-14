#!/usr/bin/env bash
# This software is a part of Isar.
# Copyright (C) Siemens AG, 2026
#
# SPDX-License-Identifier: MIT

installdata=${INSTALL_DATA:-/install}

SCRIPT_DIR=$( dirname -- "$( readlink -f -- "$0"; )"; )

. "${SCRIPT_DIR}/../lib/deploy-image-wic/handle-config.sh"
. "${SCRIPT_DIR}/sys_api.sh"
. "${SCRIPT_DIR}/installer_ui.sh"

#--------------------------------------------------------------------------
# This module contains high-level installer flow logic
# while keeping low-level backend APIs in sys_api.sh
# and user-facing dialogs in installer_ui.sh.
#--------------------------------------------------------------------------

#--------------------------------------------------------------------------
# flow_run_attended
#
# Handles all attended-mode interactions and assigns:
#   installer_image_uri
#   installer_target_dev
#
# Returns:
#   0 on success
#   1 on hard error
#   2 on user cancel
#--------------------------------------------------------------------------
flow_run_attended() {
	local default_image
	local selected_image
	local selected_target
	local target_device_size

	default_image=$(sys_first_default_image_name "$installdata")
	if [ -n "$default_image" ] && [ -f "$installdata/$default_image" ]; then
		installer_image_uri="$default_image"
	fi

	if [ -z "$installer_image_uri" ] || [ ! -f "$installdata/$installer_image_uri" ]; then
		selected_image=$(ui_select_image_menu "$installdata")
		case $? in
			0)
				installer_image_uri="$selected_image"
				;;
			1)
				ui_show_error "Could not find an image to install. Installation aborted."
				return 1
				;;
			2)
				return 2
				;;
			*)
				return 1
				;;
		esac
	fi

	if [ ! -f "$installdata/$installer_image_uri" ]; then
		ui_show_error "Could not find an image to install. Installation aborted."
		return 1
	fi

	echo "Searching for target device..."
	sys_discover_target_devices
	if [ "${#SYS_TARGET_DEVICES[@]}" -eq 0 ]; then
		ui_show_error "You need another device (besides the live device /dev/${SYS_CURRENT_ROOT_DEV}) to install the image. Installation aborted."
		return 1
	fi

	if [ "${#SYS_TARGET_DEVICES[@]}" -gt 1 ]; then
		selected_target=$(ui_select_target_device_menu "${SYS_TARGET_DEVICES[@]}")
		case $? in
			0)
				installer_target_dev="$selected_target"
				;;
			1)
				ui_show_error "No installable target devices available. Installation aborted."
				return 1
				;;
			2)
				return 2
				;;
			*)
				return 1
				;;
		esac
	else
		installer_target_dev="${SYS_TARGET_DEVICES[0]}"
	fi

	target_device_size=$(sys_device_size "$installer_target_dev")
	if ! ui_confirm_install "$installer_image_uri" "$installer_target_dev" "$target_device_size"; then
		return 2
	fi

	installer_image_uri="$installdata/$installer_image_uri"
	return 0
}

#--------------------------------------------------------------------------
# flow_validate_target_overwrite_policy
#
# Enforces overwrite policy for non-empty targets in both attended and
# unattended modes.
#
# Returns:
#   0 when policy permits installation
#   1 when policy rejects installation
#   2 when user cancels in attended mode
#--------------------------------------------------------------------------
flow_validate_target_overwrite_policy() {
	if sys_device_is_empty "$installer_target_dev"; then
		return 0
	fi

	if ! $installer_unattended; then
		if ! ui_confirm_overwrite; then
			return 2
		fi
	else
		if [ "$installer_target_overwrite" != "OVERWRITE" ]; then
			echo "Target device is not empty! -> Abort"
			echo "If you want to override existing data set \"installer.target.overwrite=OVERWRITE\" on your kernel cmdline or edit your \"auto.install\" file accordingly."
			return 1
		fi
	fi

	return 0
}

#--------------------------------------------------------------------------
# flow_maybe_switch_to_attended
#
# If unattended abort-by-key is enabled, this function offers a timeout
# window to switch to attended mode.
#--------------------------------------------------------------------------
flow_maybe_switch_to_attended() {
	local abort_file

	if [ "$installer_unattended" = true ] && [ "$installer_unattended_abort_enable" = true ]; then
		abort_file=/run/attended_mode_trigger
		if ui_countdown_allow_attended_switch "$installer_unattended_abort_timeout" "$abort_file"; then
			installer_unattended=false
		fi
	fi
}

#--------------------------------------------------------------------------
# flow_run
#
# Main installer flow combining attended/unattended execution paths.
#--------------------------------------------------------------------------
flow_run() {
	flow_maybe_switch_to_attended

	if ! $installer_unattended; then
		flow_run_attended
		case $? in
			0)
				;;
			2)
				return 0
				;;
			*)
				return 1
				;;
		esac
	fi

	flow_validate_target_overwrite_policy
	case $? in
		0)
			;;
		2)
			return 0
			;;
		*)
			return 1
			;;
	esac

	if ! $installer_unattended; then
		clear
	fi

	if ! sys_install_image_with_lock "$installer_image_uri" "$installer_target_dev"; then
		if ! $installer_unattended; then
			ui_show_error "Installation failed."
		fi
		return 1
	fi

	if ! $installer_unattended; then
		ui_show_info "Installation was successful. System will be rebooted. Please remove the USB stick."
	else
		echo "Installation was successful."
	fi

	return 0
}

# Entrypoint: run the installer flow and propagate status.
flow_run
exit $?

