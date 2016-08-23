# Script for GitLab runner
#
# Alexander Smirnov <asmirnov@ilbers.de>
# Copyright (c) 2016 ilbers GmbH

#!/bin/bash

WORKSPACE=`pwd`

. isar-init-build-env build
bitbake isar-image-base

cd $WORKSPACE
mkdir images
cd images
cp ../build/tmp/deploy/images/isar-image-base.ext4.img .
gzip -9 isar-image-base.ext4.img

cd ..
sudo rm -rf build
