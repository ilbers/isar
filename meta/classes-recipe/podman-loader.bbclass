# This software is a part of ISAR.
# Copyright (c) Siemens AG, 2024-2025
#
# SPDX-License-Identifier: MIT

inherit container-loader

CONTAINER_ENGINE = "podman"

CONTAINER_ENGINE_PACKAGES ?= "podman"
