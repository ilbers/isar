# This software is a part of ISAR.
# Copyright (c) Siemens AG, 2024-2025
#
# SPDX-License-Identifier: MIT

inherit container-loader

CONTAINER_ENGINE = "docker"

DOCKER_PKGS = "docker-cli, docker.io"
DOCKER_PKGS:buster = "docker.io"
DOCKER_PKGS:bullseye = "docker.io"
DOCKER_PKGS:bookworm = "docker.io"

CONTAINER_ENGINE_PACKAGES ?= "${DOCKER_PKGS}, apparmor"
