# Minimal target Debian root file system
#
# This software is a part of Isar.
# Copyright (C) 2024 ilbers GmbH
#
# SPDX-License-Identifier: MIT

Description = "Minimal target Debian root file system"

DEPLOY_ISAR_BOOTSTRAP = "${DEPLOY_DIR_BOOTSTRAP}/${DISTRO}-${DISTRO_ARCH}"

require isar-mmdebstrap.inc
