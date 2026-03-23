#!/bin/sh
# Build kas-based test-container
#
# Copyright (c) Siemens AG, 2026
# SPDX-License-Identifier: MIT

ISAR_DIR=$(readlink -f $(dirname $0)/../..)

eval $(grep "^KAS_CONTAINER_SCRIPT_VERSION=" ${ISAR_DIR}/kas/kas-container)
TEST_CONTAINER_VERSION=$(cat ${ISAR_DIR}/testsuite/dockerdata/version)

docker build --file ${ISAR_DIR}/testsuite/dockerdata/Dockerfile \
    --build-arg KAS_VERSION=$KAS_CONTAINER_SCRIPT_VERSION \
    --tag ${CONTAINER_BASENAME:-ghcr.io/ilbers/isar}/test-container:$TEST_CONTAINER_VERSION ${ISAR_DIR}
