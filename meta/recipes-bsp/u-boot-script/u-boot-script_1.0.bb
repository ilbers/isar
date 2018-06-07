# Boot script generator for U-Boot
#
# This software is a part of ISAR.
# Copyright (c) Siemens AG, 2018
#
# SPDX-License-Identifier: MIT

inherit dpkg-raw

DESCRIPTION = "Boot script generator for U-Boot"

SRC_URI = " \
    file://update-u-boot-script \
    file://u-boot-script \
    file://zz-u-boot-script"

DEBIAN_DEPENDS = "u-boot-tools, linux-image-${KERNEL_NAME}"

do_install() {
	# Find WKS_FILE specified for the current target.
	WKS_DIRS=$(dirname $(which wic))/lib/wic/canned-wks
	for LAYER in ${BBLAYERS}; do
		WKS_DIRS="${WKS_DIRS} ${LAYER}/scripts/lib/wic/canned-wks"
	done
	for DIR in ${WKS_DIRS}; do
		if [ -f ${DIR}/${WKS_FILE}.wks ]; then
			WKS_PATH=${DIR}/${WKS_FILE}.wks
			break
		fi
	done

	# Transfer --append parameters from a bootloader entry in the wks file
	# to the packaged /etc/default/u-boot-script.
	if [ -n ${WKS_PATH} ]; then
		APPEND=$(grep "^bootloader " ${WKS_PATH} | \
			 sed 's/.* --append=\([^ $]*\).*/\1/')
		sed -i 's|\(^KERNEL_ARGS_APPEND=\).*|\1'${APPEND}'|' \
			${WORKDIR}/u-boot-script
	fi

	sudo rm -rf ${D}/etc ${D}/usr

	install -v -d ${D}/usr/sbin
	install -v -m 755 ${WORKDIR}/update-u-boot-script ${D}/usr/sbin/

	install -v -d ${D}/etc/default
	install -v -m 644 ${WORKDIR}/u-boot-script ${D}/etc/default/

	install -v -d ${D}/etc/kernel/postinst.d
	install -v -m 755 ${WORKDIR}/zz-u-boot-script ${D}/etc/kernel/postinst.d

	sudo chown -R root:root ${D}/etc ${D}/usr
}
