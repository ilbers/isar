#
# Copyright (c) Siemens AG, 2018-2020
#
# SPDX-License-Identifier: MIT

MAINTAINER = "isar-users <isar-users@googlegroups.com>"

require u-boot-${PV}.inc

# Just for testing purposes, distro package would be recent enough
U_BOOT_TOOLS_PACKAGE = "1"

COMPATIBLE_MACHINE = "^(de0-nano-soc)$"

do_prepare_build:append:buster() {
	echo =-=-=
cat << _EOF_ >> ${S}/debian/rules
override_dh_dwz:
	dh_dwz || :
_EOF_
}
