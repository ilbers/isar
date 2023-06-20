# CI root filesystem for target installation
#
# This software is a part of ISAR.
# Copyright (C) 2023 ilbers GmbH

require recipes-core/images/isar-image-base.bb

FILESEXTRAPATHS:append = ":${LAYERDIR_isar}/recipes-core/images:"

# Avoid ISAR_RELEASE_CMD warning in image.bbclass
ISAR_RELEASE_CMD = "git -C ${LAYERDIR_test} describe --tags --dirty --match 'v[0-9].[0-9]*'"

# Setup SSH server on board
IMAGE_INSTALL += "isar-ci-ssh-setup"
