#
# Copyright (c) Siemens AG, 2024
#
# Authors:
#  Jan Kiszka <jan.kiszka@siemens.com>
#
# SPDX-License-Identifier: MIT
#

FILESPATH:append := ":${FILE_DIRNAME}/files"

inherit dpkg-raw

SRC_URI = " \
    file://hook-header.tmpl \
    file://script-header.tmpl"

TEMPLATE_FILES = " \
    hook-header.tmpl \
    script-header.tmpl"

TEMPLATE_VARS:append = " \
    HOOK_PREREQ \
    HOOK_ADD_MODULES \
    HOOK_COPY_EXECS \
    SCRIPT_PREREQ"

HOOK_PREREQ ?= ""
HOOK_ADD_MODULES ?= ""
HOOK_COPY_EXECS ?= ""
SCRIPT_PREREQ ?= ""

DEBIAN_DEPENDS = "initramfs-tools"

def get_initramfs_hook_name(d):
    name = d.getVar('BPN')
    if name.startswith("initramfs-"):
        name = name[10:]
    if name.endswith("-hook"):
        name = name[:-5]
    return name

INITRAMFS_HOOK_NAME ?= "${@get_initramfs_hook_name(d)}"

do_install() {
	if [ -f "${WORKDIR}/hook" ] || [ -n "${HOOK_COPY_EXECS}" ] || \
	   [ -n "${HOOK_ADD_MODULES}" ]; then
		rm -rf "${D}/usr/share/initramfs-tools/hooks"
		install -d -m 0755 "${D}/usr/share/initramfs-tools/hooks"

		install -m 0755 "${WORKDIR}/hook-header" \
			"${D}/usr/share/initramfs-tools/hooks/${INITRAMFS_HOOK_NAME}"
		if [ -f "${WORKDIR}/hook" ]; then
			cat "${WORKDIR}/hook" >> \
			    "${D}/usr/share/initramfs-tools/hooks/${INITRAMFS_HOOK_NAME}"
		else
			echo "exit 0" >> \
			    "${D}/usr/share/initramfs-tools/hooks/${INITRAMFS_HOOK_NAME}"
		fi
	fi

	for script in init-top init-premount local-top nfs-top local-block \
		      local-premount nfs-premount local-bottom nfs-bottom \
		      init-bottom; do
		if [ ! -f "${WORKDIR}/$script" ] && [ ! -f "${WORKDIR}/${script}-complete" ]; then
			continue
		fi

		rm -rf "${D}/usr/share/initramfs-tools/scripts/$script"
		install -d -m 0755 "${D}/usr/share/initramfs-tools/scripts/$script"
		if [ -f "${WORKDIR}/${script}" ]; then
			install -m 0755 "${WORKDIR}/script-header" \
				"${D}/usr/share/initramfs-tools/scripts/$script/${INITRAMFS_HOOK_NAME}"
			cat "${WORKDIR}/$script" >> \
			    "${D}/usr/share/initramfs-tools/scripts/$script/${INITRAMFS_HOOK_NAME}"
		else
			install -m 0755 "${WORKDIR}/${script}-complete" \
				"${D}/usr/share/initramfs-tools/scripts/$script/${INITRAMFS_HOOK_NAME}"
		fi
	done
}
