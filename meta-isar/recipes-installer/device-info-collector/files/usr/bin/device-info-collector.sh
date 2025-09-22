#!/usr/bin/env bash
# This software is a part of ISAR.
# Copyright (C) Siemens AG, 2024-2025
#
# SPDX-License-Identifier: MIT

BASE_DIR="/install/device-infos"

SERIAL_NUMBER=$(dmidecode -s system-serial-number | tr '[:upper:]' '[:lower:]' | tr -d "[:space:]")
TARGET_DIR="${BASE_DIR}/${SERIAL_NUMBER}/$(date -u +%4Y-%m-%d_%H-%S)"

echo "Use ${TARGET_DIR} to store the collected device infos."
mkdir -p ${TARGET_DIR}

echo "Collecting most important device attributes..."

echo "Collecting peripherals"
lshw >> ${TARGET_DIR}/lshw.out
lspci >> ${TARGET_DIR}/lspci.out
lsusb >> ${TARGET_DIR}/lsusb.out
lsblk >> ${TARGET_DIR}/lsblk.out

echo "Collecting cpu info..."
lscpu >> ${TARGET_DIR}/lscpu.out
cat /proc/cpuinfo > ${TARGET_DIR}/proc_cpuinfo

echo "Collecting dmi / smbios..."
dmidecode --dump-bin ${TARGET_DIR}/dmidecode.dump
