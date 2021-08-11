# Minimal target Debian root file system
#
# This software is a part of ISAR.
# Copyright (c) Siemens AG, 2018
#
# SPDX-License-Identifier: MIT

Description = "Minimal target Debian root file system"

DEPLOY_ISAR_BOOTSTRAP = "${DEPLOY_DIR_BOOTSTRAP}/${DISTRO}-${DISTRO_ARCH}"

require isar-bootstrap.inc
