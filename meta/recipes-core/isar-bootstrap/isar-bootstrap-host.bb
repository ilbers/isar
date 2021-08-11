# Minimal host Debian root file system
#
# This software is a part of ISAR.
# Copyright (c) Siemens AG, 2018
#
# SPDX-License-Identifier: MIT

Description = "Minimal host Debian root file system"

DEPLOY_ISAR_BOOTSTRAP = "${DEPLOY_DIR_BOOTSTRAP}/${HOST_DISTRO}-host_${DISTRO}-${DISTRO_ARCH}"

DISTRO_VARS_PREFIX = "HOST_"

require isar-bootstrap.inc

HOST_DISTRO_BOOTSTRAP_KEYS ?= ""
DISTRO_BOOTSTRAP_KEYS = "${HOST_DISTRO_BOOTSTRAP_KEYS}"

OVERRIDES_append = ":${@get_distro_needs_https_support(d, True)}"

do_bootstrap() {
    isar_bootstrap --host
}
