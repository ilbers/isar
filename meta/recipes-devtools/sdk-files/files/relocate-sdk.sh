#!/bin/sh
#
# This software is a part of ISAR.
# Copyright (c) Siemens AG, 2020-2023
#
# SPDX-License-Identifier: MIT

sdkroot=$(realpath $(dirname $0))
arch=$(uname -m)

new_sdkroot=$sdkroot

case "$1" in
--help|-h)
	echo "Usage: $0 [--restore-chroot|-r]"
	exit 0
	;;
--restore-chroot|-r)
	new_sdkroot=/
	;;
esac

if [ -z $(which patchelf 2>/dev/null) ]; then
	echo "Please install 'patchelf' package first."
	exit 1
fi

echo -n "Adjusting path of SDK to '${new_sdkroot}'... "

for binary in $(find ${sdkroot}/usr/bin ${sdkroot}/usr/sbin ${sdkroot}/usr/lib/gcc* -executable -type f -exec file {} \; | grep ELF | awk -F ':' '{ print $1 }'); do
	interpreter=$(patchelf --print-interpreter ${binary} 2>/dev/null)
	oldpath=${interpreter%/lib*/ld-linux*}
	interpreter=${interpreter#${oldpath}}
	if [ -n "${interpreter}" ]; then
		patchelf --set-interpreter ${new_sdkroot}${interpreter} \
			--set-rpath ${new_sdkroot}/usr/lib:${new_sdkroot}/usr/lib/${arch}-linux-gnu \
			--force-rpath \
			$binary 2>/dev/null
	fi
done

sed -i 's|^GCC_SYSROOT=.*|GCC_SYSROOT="'"${new_sdkroot}"'"|' \
    ${sdkroot}/usr/bin/gcc-sysroot-wrapper.sh

echo "done"
