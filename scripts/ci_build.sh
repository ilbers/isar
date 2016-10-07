# Script for GitLab runner
#
# Alexander Smirnov <asmirnov@ilbers.de>
# Copyright (c) 2016 ilbers GmbH

#!/bin/sh

# Export $PATH to use 'parted' tool
export PATH=$PATH:/sbin

WORKSPACE=`pwd`

. isar-init-build-env build
bitbake multiconfig:qemuarm:isar-image-base multiconfig:rpi:isar-image-base multiconfig:qemuarm:isar-image-debug multiconfig:rpi:isar-image-debug

cd $WORKSPACE
mkdir images
cd images

# Get QEMU image
cp ../build/tmp/deploy/images/isar-image-base-qemuarm.ext4.img .
gzip -9 isar-image-base-qemuarm.ext4.img

# Get RPi SD card image
cp ../build/tmp/deploy/images/isar-image-base.rpi-sdimg .
gzip -9 isar-image-base.rpi-sdimg

cd ..
sudo rm -rf build
