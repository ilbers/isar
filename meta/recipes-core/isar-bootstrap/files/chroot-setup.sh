#!/bin/sh
#
# Copyright (c) David Whedon <dwhedon@debian.org>, 2001
# Copyright (c) Tollef Fog Heen <tfheen@debian.org>, 2002
# Copyright (c) Thorsten Sauter <tsauter@gmx.net>, 2003
# Copyright (c) Rob Landley <rob@landley.net>, 2003
# Copyright (c) Joey Hess <joeyh@debian.org>, 2003
# Copyright (c) Colin Watson <cjwatson@debian.org>, 2005
# Copyright (c) Siemens AG, 2018 (changes authored by Claudius Heine <ch@denx.de>)
#
# This file is based on:
# https://salsa.debian.org/installer-team/debian-installer-utils/blob/master/chroot-setup.sh
# Link to the original copyright notice:
# https://salsa.debian.org/installer-team/debian-installer-utils/blob/master/debian/copyright
#
# SPDX-License-Identifier: GPL-2.0

usage() {
	cat <<-EOF 1>&2
		Script to setup and cleanup chroot environments.
		This script setups chroot environments so that
		startup of daemons from debian package scripts
		is prevented.

		Usage:
		$(basename "$0") [command] [parameters]
		commands:
		    setup [target path]    Setup chroot environment
		    cleanup [target path]  Cleanup chroot environment
	EOF
}

check_target() {
	TARGET="${1:-""}"

	if [ -z "${TARGET}" ]; then
		echo "Please set a target." 1>&2
		echo 1>&2
		usage
		return 1
	fi

	# Bail out if directories we need are not there
	if [ ! -d "/${TARGET}/sbin" ] || [ ! -d "/${TARGET}/usr/sbin" ] || \
	   [ ! -d "/${TARGET}/proc" ]; then
		echo "Target '${TARGET}' does not exist or does contain"\
			"required directories" 1>&2
		echo 1>&2
		usage
		return 1
	fi

	return 0
}

divert () {
	TARGET="${1:-""}"

	check_target "${TARGET}" || return 1

	chroot "/${TARGET}" dpkg-divert --quiet --add --divert "$2.REAL" --rename "$2"
}

undivert () {
	TARGET="${1:-""}"

	check_target "${TARGET}" || return 1

	rm -f "/${TARGET}$2"
	chroot "/${TARGET}" dpkg-divert --quiet --remove --rename "$2"
}

chroot_setup() {
	TARGET="${1:-""}"

	check_target "${TARGET}" || return 1

	# Create a policy-rc.d to stop maintainer scripts using invoke-rc.d
	# from running init scripts. In case of maintainer scripts that do not
	# use invoke-rc.d, add a dummy start-stop-daemon.
	if [ -e "/${TARGET}/sbin/policy-rc.d" ]; then
		divert "${TARGET}" /sbin/policy-rc.d
	fi
	cat > "/${TARGET}/usr/sbin/policy-rc.d" <<-EOF
		#!/bin/sh
		exit 101
	EOF
	chmod a+rx "/${TARGET}/usr/sbin/policy-rc.d"

	if [ -e "/${TARGET}/sbin/start-stop-daemon" ]; then
		divert "${TARGET}" /sbin/start-stop-daemon
	fi
	cat > "/${TARGET}/sbin/start-stop-daemon" <<-EOF
		#!/bin/sh
		echo 1>&2
		echo 'Warning: Fake start-stop-daemon called, doing nothing.' 1>&2
		exit 0
	EOF
	chmod a+rx "/${TARGET}/sbin/start-stop-daemon"

	# If Upstart is in use, add a dummy initctl to stop it starting jobs.
	if [ -x "/${TARGET}/sbin/initctl" ]; then
		divert "${TARGET}" /sbin/initctl
		cat > "/${TARGET}/sbin/initctl" <<-EOF
			#!/bin/sh
			if [ "\$1" = version ]; then exec /sbin/initctl.REAL "\$@"; fi
			echo 1>&2
			echo 'Warning: Fake initctl called, doing nothing.' 1>&2
			exit 0
		EOF
		chmod a+rx "/${TARGET}/sbin/initctl"
	fi
}

chroot_cleanup() {
	TARGET="${1:-""}"

	check_target "${TARGET}" || return 1

	undivert "${TARGET}" /usr/sbin/policy-rc.d
	undivert "${TARGET}" /sbin/start-stop-daemon
	if [ -x "/${TARGET}/sbin/initctl.REAL" ]; then
		undivert "${TARGET}" /sbin/initctl
	fi
}

main() {
	CMD="${1:-""}"

	if [ -z "${CMD}" ]; then
		usage
		return 1
	fi
	shift

	case "${CMD}" in
		"setup")
			chroot_setup "$@";;
		"cleanup")
			chroot_cleanup "$@";;
		*)
			echo "Unknown command '${CMD}'." 1>&2
			echo 1>&2
			usage
			return 1;;
	esac
}

main "$@"
