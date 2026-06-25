#!/bin/sh
# Script to run testsuite inside the official test-container
#
# Copyright (c) Siemens AG, 2026
# SPDX-License-Identifier: MIT

ISAR_DIR=$(readlink -f $(dirname $0)/..)

TEST_CONTAINER_VERSION=$(cat ${ISAR_DIR}/testsuite/dockerdata/version)

# The way to do this after kas 5.2:
# export KAS_CONTAINER_IMAGE="${CONTAINER_BASENAME:-ghcr.io/ilbers/isar}/test-container:$TEST_CONTAINER_VERSION"
#
# For now:
export KAS_CONTAINER_IMAGE_DISTRO="container:$TEST_CONTAINER_VERSION"
export KAS_CONTAINER_IMAGE=${CONTAINER_BASENAME:-ghcr.io/ilbers/isar}/test

ISAR_FLAG="--isar"
case "$*" in
    *"-p rootless=1"*) ISAR_FLAG="--isar-rootless" ;;
esac

${ISAR_DIR}/kas/kas-container ${ISAR_FLAG} --repo-ro shell -c "$*"
