# This software is a part of ISAR.
# Copyright (c) Siemens AG, 2024
#
# SPDX-License-Identifier: MIT

require recipes-support/container-loader/podman-loader.inc

SRC_URI += "\
    docker://quay.io/libpod/alpine;tag=latest \
    "
