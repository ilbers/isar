# Boot script generator for U-Boot
#
# This software is a part of ISAR.
# Copyright (c) Siemens AG, 2018
#
# SPDX-License-Identifier: MIT

inherit dpkg-raw
inherit wks-file

WKS_FULL_PATH = "${@get_wks_full_path(d)}"

DESCRIPTION = "Boot script generator for U-Boot"

PN .= "-${KERNEL_NAME}"

SRC_URI = " \
    file://update-u-boot-script \
    file://u-boot-script \
    file://zz-u-boot-script"

DEBIAN_DEPENDS = "u-boot-tools, linux-image-${KERNEL_NAME}"

# Extract the following information from the wks file and add it to the
# packaged /etc/default/u-boot-script:
#  - --append parameters from a bootloader entry
#  - root partition number
#  - disk name the root partition is located on

init_config_from_wks() {
	# Filter out the bootloader line, then grap the argument of --append.
	# The argument may be quoted, respect that but remove the quotes prior
	# to assigning the target variable. Will be re-added later.
	KERNEL_ARGS=$(grep "^bootloader " $1 | \
		      sed -e 's/.* --append[= ]\(".*"\|[^ $]*\).*/\1/' \
			  -e 's/\"\(.*\)\"/\1/')

	COUNT=0
	while read COMMAND MNT OPTIONS; do
		if [ "${COMMAND}" != part ] ||
		   echo "${OPTIONS}" | grep -q "\--no-table"; then
			continue
		fi
		COUNT=$(expr ${COUNT} + 1)
		if [ "${MNT}" = "/" ]; then
			ROOT_PARTITION=${COUNT}
			break
		fi
	done < $1
	if [ -n "${ROOT_PARTITION}" ]; then
		# filter out parameter of --ondisk or --ondrive
		ROOT=$(echo ${OPTIONS} | \
		       sed 's/.*--on\(disk\|drive\)[ ]\+\([^ ]\+\) .*/\2/')
		# anything found?
		if [ "${ROOT}" != "${OPTIONS}" ]; then
			# special case: append 'p' to mmcblkN
			ROOT=$(echo ${ROOT} | sed 's/^\(mmcblk[0-9]\+\)/\1p/')

			KERNEL_ARGS="\"root=/dev/${ROOT}${ROOT_PARTITION} ${KERNEL_ARGS}\""
		fi
	fi

	sed -i -e 's|\(^ROOT_PARTITION=\).*|\1\"'"${ROOT_PARTITION}"'\"|' \
	       -e 's|\(^KERNEL_ARGS=\).*|\1'"${KERNEL_ARGS}"'|' \
		${WORKDIR}/u-boot-script
}

do_install() {
	[ -n ${WKS_FULL_PATH} ] && init_config_from_wks "${WKS_FULL_PATH}"

	sudo rm -rf ${D}/etc ${D}/usr

	install -v -d ${D}/usr/sbin
	install -v -m 755 ${WORKDIR}/update-u-boot-script ${D}/usr/sbin/

	install -v -d ${D}/etc/default
	install -v -m 644 ${WORKDIR}/u-boot-script ${D}/etc/default/

	install -v -d ${D}/etc/kernel/postinst.d
	install -v -m 755 ${WORKDIR}/zz-u-boot-script ${D}/etc/kernel/postinst.d
}
