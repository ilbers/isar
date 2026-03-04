# This software is a part of ISAR.
# Copyright (c) Siemens AG, 2024-2025
#
# SPDX-License-Identifier: MIT

inherit podman-loader

MAINTAINER = "isar-users <isar-users@googlegroups.com>"

SRC_URI += "\
    docker://quay.io/libpod/alpine;tag=latest \
    "
