#!/usr/bin/env bash
#
# sys_api.sh — Ported installer system APIs
# -------------------------------------------------------------------

# Load shared framework utilities
source ./func.sh || {
    echo "Error: func.sh not found or not readable." >&2
    exit 1
}

# -------------------------------------------------------------------
# API: locate_disk_images
# Description:
#   Find disk image files (.wic, .wic.bz2) under given path.
# Usage:
#   sys_locate_disk_images search_path=/install
# Returns JSON:
#   {"error":"", "retval":"0", "images":["/install/image.wic", ...]}
# -------------------------------------------------------------------
sys_locate_disk_images() {
    local -A ARGS
    local required=(search_path)
    api_args ARGS required[@] "$@" || {
        pack_return_data error "$_args_error" retval "1"
        return 1
    }

    local fn="${FUNCNAME[0]}"
    local path="${ARGS[search_path]}"

    log_info "$fn" "Searching for disk images in '$path'"

    local images
    images=$(find "$path" -type f -iname "*.wic*" ! -iname "*.wic.bmap" 2>/dev/null)

    # when no images found in /install
    if [[ -z "$images" ]]; then
        log_warn "$fn" "No images found."
        pack_return_data error "No images found" retval "1"
        return 1
    fi

    # Convert newline-separated paths into JSON array elements
    local json_images
    json_images=$(printf '"%s",' $images | sed 's/,$//')
    # final JSON response on stdout
    echo "{ \"error\":\"\", \"retval\":\"0\", \"images\":[${json_images}] }"
}


# -------------------------------------------------------------------
# API: sys_list_valid_target_devices
# Description:
#   Shell-friendly variant of sys_get_valid_target_devices.
#   Prints one valid device per line (absolute path).
# Usage:
#   sys_list_valid_target_devices
# Output:
#   /dev/sdb
#   /dev/sdc
# -------------------------------------------------------------------
sys_list_valid_target_devices() {
    local dev

    for dev in /sys/block/*; do
        dev=$(basename "$dev")

        case "$dev" in
            loop*|ram*|sr*|mtd*)
                continue
                ;;
        esac

        # skip inactive md devices
        if [[ "$dev" == md* ]]; then
            [ -f "/sys/block/$dev/md/array_state" ] || continue
            state=$(cat /sys/block/$dev/md/array_state)
            [ "$state" = "active" ] || [ "$state" = "clean" ] || continue
        fi

        echo "/dev/$dev"
    done
}
