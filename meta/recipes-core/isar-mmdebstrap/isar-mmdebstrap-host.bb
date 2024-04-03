# Minimal host Debian root file system
#
# This software is a part of Isar.
# Copyright (C) 2024 ilbers GmbH
#
# SPDX-License-Identifier: MIT

Description = "Minimal host Debian root file system"

DEPLOY_ISAR_BOOTSTRAP = "${DEPLOY_DIR_BOOTSTRAP}/${HOST_DISTRO}-host_${DISTRO}-${DISTRO_ARCH}"

PROVIDES += "bootstrap-host"

BOOTSTRAP_FOR_HOST = "1"

require isar-mmdebstrap.inc

HOST_DISTRO_BOOTSTRAP_KEYS ?= ""
DISTRO_BOOTSTRAP_KEYS = "${HOST_DISTRO_BOOTSTRAP_KEYS}"
