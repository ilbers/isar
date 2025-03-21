#!/bin/sh
# Script to setup a container for CI builds
#
# Cedric Hombourger <cedric.hombourger@siemens.com>
# Copyright (c) Siemens AG, 2025
# SPDX-License-Identifier: MIT

gpg_key=/etc/apt/trusted.gpg.d/debian-isar.gpg
[ -f "${gpg_key}" ] || {
    wget -q http://deb.isar-build.org/debian-isar.key -O- \
    | gpg --dearmor \
    | sudo dd of="${gpg_key}"
}

list=/etc/apt/sources.list.d/10-isar_build.list
[ -f "${list}" ] || {
    echo "deb [signed-by=/etc/apt/trusted.gpg.d/debian-isar.gpg] \
        http://deb.isar-build.org/debian-isar bookworm-isar main" \
    | sudo tee /etc/apt/sources.list.d/10-isar_build.list
}

tools="avocado qemu-system-aarch64 qemu-system-arm qemu-system-i386 qemu-system-x86_64"
need_install=0
for tool in ${tools}; do
    which "${tool}" || need_install=1
done
[ "${need_install}" = "0" ] || {
    sudo apt-get update
    sudo apt-get install -y avocado qemu-system-arm qemu-system-x86
}

exec /container-entrypoint ${*}
