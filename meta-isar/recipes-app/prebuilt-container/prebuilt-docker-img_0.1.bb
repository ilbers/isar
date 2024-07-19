# This software is a part of ISAR.
# Copyright (c) Siemens AG, 2024
#
# SPDX-License-Identifier: MIT

require recipes-support/container-loader/docker-loader.inc

CONTAINER_DELETE_AFTER_LOAD = "1"

SRC_URI += "\
    docker://quay.io/libpod/alpine;digest=sha256:fa93b01658e3a5a1686dc3ae55f170d8de487006fb53a28efcd12ab0710a2e5f;tag=3.10.2 \
    "
