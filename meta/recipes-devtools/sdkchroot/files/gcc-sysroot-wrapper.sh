#!/bin/sh
#
# This software is a part of ISAR.
# Copyright (c) Siemens AG, 2020
#
# SPDX-License-Identifier: MIT

GCC_SYSROOT=

NEXT_TARGET=$0
until [ "${NEXT_TARGET##*/}" = "gcc-sysroot-wrapper.sh" ]; do
	TARGET=${NEXT_TARGET}
	NEXT_TARGET=$(dirname ${TARGET})/$(readlink ${TARGET})
done

${TARGET}.bin --sysroot=${GCC_SYSROOT} "$@"
