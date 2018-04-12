# Script for Jenkins build
#
# Alexander Smirnov <asmirnov@ilbers.de>
# Copyright (c) 2016-2017 ilbers GmbH

#!/bin/sh

# Export $PATH to use 'parted' tool
export PATH=$PATH:/sbin

# Get parameters from the command line
WORKSPACE=$1
GIT_COMMIT=$2

# Go to Isar root
cd $(dirname $0)/..

# Setup build folder for current revision
if [ ! -d /build/$WORKSPACE/$GIT_COMMIT ]; then
        mkdir -p /build/$WORKSPACE/$GIT_COMMIT
fi
source isar-init-build-env /build/$WORKSPACE/$GIT_COMMIT

# Start build for all possible configurations
bitbake -v \
        multiconfig:qemuarm-wheezy:isar-image-base \
        multiconfig:qemuarm-jessie:isar-image-base \
        multiconfig:qemuarm-stretch:isar-image-base \
        multiconfig:qemuarm64-stretch:isar-image-base \
        multiconfig:qemui386-jessie:isar-image-base \
        multiconfig:qemui386-stretch:isar-image-base \
        multiconfig:qemuamd64-jessie:isar-image-base \
        multiconfig:qemuamd64-stretch:isar-image-base \
        multiconfig:rpi-jessie:isar-image-base
