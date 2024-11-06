# Minimal host Debian root file system
#
# This software is a part of ISAR.
# Copyright (c) Siemens AG, 2018
#
# SPDX-License-Identifier: MIT

Description = "Minimal host Debian root file system"

DEPLOY_ISAR_BOOTSTRAP = "${DEPLOY_DIR_BOOTSTRAP}/${HOST_DISTRO}-host_${DISTRO}-${DISTRO_ARCH}"

PROVIDES += "bootstrap-host"

BOOTSTRAP_FOR_HOST = "1"

require isar-bootstrap.inc

HOST_DISTRO_BOOTSTRAP_KEYS ?= ""
DISTRO_BOOTSTRAP_KEYS = "${HOST_DISTRO_BOOTSTRAP_KEYS}"
