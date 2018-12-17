# Debug root filesystem for target installation
#
# This software is a part of ISAR.
# Copyright (C) 2015-2016 ilbers GmbH

require recipes-core/images/isar-image-base.bb

IMAGE_PREINSTALL += "gdb \
                     strace"
