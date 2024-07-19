# This software is a part of ISAR.
# Copyright (c) Siemens AG, 2024
#
# SPDX-License-Identifier: MIT

require container-loader.inc

CONTAINER_ENGINE = "docker"

CONTAINER_ENGINE_PACKAGES ?= "docker.io, apparmor"
