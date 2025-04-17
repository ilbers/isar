#!/usr/bin/env bash
# This software is a part of ISAR.
# Copyright (C) Siemens AG, 2024
#
# SPDX-License-Identifier: MIT

installer_unattended=false
installer_image_uri=
installer_target_dev=
installer_target_overwrite=

if [ -f "$installdata/auto.install" ]; then
    exec 3<"$installdata/auto.install"
    read -r installer_image_uri <&3
    read -r installer_target_dev <&3
    read -r installer_target_overwrite <&3
    exec 3>&-

    installer_unattended=true
fi

# But let kernel cmdline overrule
for x in $(cat /proc/cmdline); do
    case $x in
        installer.unattended*)
            installer_unattended=true
        ;;
        installer.image.uri=*)
            installer_image_uri=${x#installer.image.uri=}
            installer_unattended=true
        ;;
        installer.target.dev=*)
            installer_target_dev=${x#installer.target.dev=}
            installer_target_dev_list=$(echo "$installer_target_dev" | sed 's/[,:]/ /g')
            boot_device=$(lsblk -no PKNAME,MOUNTPOINT | grep -E '/boot| /$' | awk '{print "/dev/"$1}' | uniq)
            for dev in ${installer_target_dev_list}; do
                if [ -b "${dev}" ] && [ "${dev}" != "${boot_device}" ]; then
                    installer_target_dev=${dev}
                    break
                fi
            done
            installer_unattended=true
        ;;
        installer.target.overwrite*)
            installer_target_overwrite="OVERWRITE"
            installer_unattended=true
        ;;
    esac
done

## Check config
all_values_set=false
if [ -n "${installer_image_uri}" ] && [ -n "${installer_target_dev}" ] && [ -n "${installer_target_overwrite}" ]; then
    all_values_set=true
fi

if ${installer_unattended} && ! ${all_values_set}; then
    echo "When running in unattended mode all values needed for installation have to be set! -> Abort"
    exit 1
fi

if ${installer_unattended}; then
    echo "Got config:"
    echo "  installer_unattended=${installer_unattended}"
    echo "  installer_image_uri=${installer_image_uri}"
    echo "  installer_target_dev=${installer_target_dev}"
    echo "  installer_target_overwrite=${installer_target_overwrite}"

    case ${installer_target_overwrite} in
        OVERWRITE|ABORT)
        ;;
        *)
            echo "When running in unattended mode only \"installer_target_overwrite=OVERWRITE | ABORT\" is valid! You specified \"${installer_target_overwrite}\" -> Abort"
            exit 1
        ;;
    esac

    if [ ! -b ${installer_target_dev} ]; then
        echo "Target device \"${installer_target_dev}\" is not a valid block device. -> Abort"
        exit 1
    fi

    if [ ! -f "${installer_image_uri}" ]; then
        if [ ! -f "$installdata/${installer_image_uri}" ]; then
            echo "Could not find image file ${installer_image_uri} nor $installdata/${installer_image_uri} to install. -> Abort"
            exit 1
        else
            installer_image_uri=$installdata/${installer_image_uri}
        fi
    fi
fi
