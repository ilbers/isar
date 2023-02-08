# CI root filesystem for target installation
#
# This software is a part of ISAR.
# Copyright (C) 2023 ilbers GmbH

require recipes-core/images/isar-image-base.bb

# Setup SSH server on board
IMAGE_INSTALL += "isar-ci-ssh-setup"
