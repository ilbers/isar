#!/usr/bin/env bash
# Script for CI system build
#
# Alexander Smirnov <asmirnov@ilbers.de>
# Copyright (c) 2016-2018 ilbers GmbH

set -e

ES_BUG=3

# Export $PATH to use 'parted' tool
export PATH=$PATH:/sbin

# Go to Isar root
cd "$(dirname "$0")/.."

# Start build in Isar tree by default
BUILD_DIR=./build

BB_ARGS="-v"

TARGETS_SET="\
            mc:qemuarm-stretch:isar-image-base \
            mc:qemuarm-buster:isar-image-base \
            mc:qemuarm64-stretch:isar-image-base \
            mc:qemui386-stretch:isar-image-base \
            mc:qemui386-buster:isar-image-base \
            mc:qemuamd64-stretch:isar-image-base \
            mc:qemuamd64-buster:isar-image-base \
            mc:qemuamd64-buster-tgz:isar-image-base \
            mc:qemumipsel-stretch:isar-image-base \
            mc:qemumipsel-buster:isar-image-base \
            mc:nand-ubi-demo-buster:isar-image-ubi \
            mc:rpi-stretch:isar-image-base"
          # qemu-user-static of <= buster too old to build that
          # mc:qemuarm64-buster:isar-image-base
          # mc:qemuarm64-bullseye:isar-image-base

TARGETS_SET_BULLSEYE="\
    mc:qemuamd64-bullseye:isar-image-base \
    mc:qemuarm-bullseye:isar-image-base \
    mc:qemui386-bullseye:isar-image-base \
    mc:qemumipsel-bullseye:isar-image-base \
"

CROSS_TARGETS_SET="\
                  mc:qemuarm-stretch:isar-image-base \
                  mc:qemuarm-buster:isar-image-base \
                  mc:qemuarm64-stretch:isar-image-base \
                  mc:qemuamd64-stretch:isar-image-base \
                  mc:de0-nano-soc-stretch:isar-image-base \
                  mc:rpi-stretch:isar-image-base"

CROSS_TARGETS_SET_BULLSEYE="\
    mc:qemuarm-bullseye:isar-image-base \
"

REPRO_TARGETS_SET_SIGNED="\
            mc:de0-nano-soc-stretch:isar-image-base \
            mc:qemuarm64-stretch:isar-image-base"

REPRO_TARGETS_SET="\
            mc:qemuamd64-stretch:isar-image-base \
            mc:qemuarm-buster:isar-image-base"

show_help() {
    echo "This script builds the default Isar images."
    echo
    echo "Usage:"
    echo "    $0 [params]"
    echo
    echo "Parameters:"
    echo "    -b, --build BUILD_DIR    set path to build directory. If not set,"
    echo "                             the build will be started in current path."
    echo "    -c, --cross              enable cross-compilation."
    echo "    -d, --debug              enable debug bitbake output."
    echo "    -f, --fast               cross build reduced set of configurations."
    echo "    -q, --quiet              suppress verbose bitbake output."
    echo "    -r, --repro              enable use of cached base repository."
    echo "    --help                   display this message and exit."
    echo
    echo "Exit status:"
    echo " 0  if OK,"
    echo " 3  if invalid parameters are passed."
}

# Parse command line to get user configuration
while [ $# -gt 0 ]
do
    key="$1"

    case $key in
    -h|--help)
        show_help
        exit 0
        ;;
    -b|--build)
        BUILD_DIR="$2"
        shift
        ;;
    -c|--cross)
        CROSS_BUILD="1"
        ;;
    -d|--debug)
        BB_ARGS="$BB_ARGS -D"
        ;;
    -f|--fast)
        # Start build for the reduced set of configurations
        # Enforce cross-compilation to speed up the build
        FAST_BUILD="1"
        CROSS_BUILD="1"
        ;;
    -q|--quiet)
        BB_ARGS=""
        ;;
    -r|--repro)
        REPRO_BUILD="1"
        # This switch is deprecated, just here to not cause failing CI on
        # legacy configs
        case "$2" in
        -s|--sign) shift ;;
        esac
        ;;
    *)
        echo "error: invalid parameter '$key', please try '--help' to get list of supported parameters"
        exit $ES_BUG
        ;;
    esac

    shift
done

# the real stuff starts here, trace commands from now on
set -x

# Setup build folder for the current build
if [ ! -d "$BUILD_DIR" ]; then
        mkdir -p "$BUILD_DIR"
fi
source isar-init-build-env "$BUILD_DIR"

if [ -n "$CROSS_BUILD" ]; then
    sed -i -e 's/ISAR_CROSS_COMPILE ?= "0"/ISAR_CROSS_COMPILE ?= "1"/g' conf/local.conf
fi

if [ -n "$REPRO_BUILD" ]; then
    ISAR_TESTSUITE_GPG_PUB_KEY_FILE="$ISARROOT/testsuite/base-apt/test_pub.key"
    ISAR_TESTSUITE_GPG_PRIV_KEY_FILE="$ISARROOT/testsuite/base-apt/test_priv.key"
    export GNUPGHOME=$(mktemp -d)
    gpg --import $ISAR_TESTSUITE_GPG_PUB_KEY_FILE $ISAR_TESTSUITE_GPG_PRIV_KEY_FILE

    # Enable use of signed cached base repository
    echo BASE_REPO_KEY=\"file://$ISAR_TESTSUITE_GPG_PUB_KEY_FILE\" >> conf/local.conf
    bitbake $BB_ARGS $REPRO_TARGETS_SET_SIGNED
    while [ -e bitbake.sock ]; do sleep 1; done
    sudo rm -rf tmp
    sed -i -e 's/#ISAR_USE_CACHED_BASE_REPO ?= "1"/ISAR_USE_CACHED_BASE_REPO ?= "1"/g' conf/local.conf
    sed -i -e 's/^#BB_NO_NETWORK/BB_NO_NETWORK/g' conf/local.conf
    bitbake $BB_ARGS $REPRO_TARGETS_SET_SIGNED
    while [ -e bitbake.sock ]; do sleep 1; done
    # Cleanup and disable use of signed cached base repository
    sudo rm -rf tmp
    sed -i -e 's/ISAR_USE_CACHED_BASE_REPO ?= "1"/#ISAR_USE_CACHED_BASE_REPO ?= "1"/g' conf/local.conf
    sed -i -e 's/^BB_NO_NETWORK/#BB_NO_NETWORK/g' conf/local.conf
    sed -i -e 's/^BASE_REPO_KEY/#BASE_REPO_KEY/g' conf/local.conf

    # Enable use of unsigned cached base repository
    bitbake $BB_ARGS $REPRO_TARGETS_SET
    while [ -e bitbake.sock ]; do sleep 1; done
    sudo rm -rf tmp
    sed -i -e 's/#ISAR_USE_CACHED_BASE_REPO ?= "1"/ISAR_USE_CACHED_BASE_REPO ?= "1"/g' conf/local.conf
    sed -i -e 's/^#BB_NO_NETWORK/BB_NO_NETWORK/g' conf/local.conf
    bitbake $BB_ARGS $REPRO_TARGETS_SET
    while [ -e bitbake.sock ]; do sleep 1; done
    # Cleanup and disable use of unsigned cached base repository
    sudo rm -rf tmp
    sed -i -e 's/ISAR_USE_CACHED_BASE_REPO ?= "1"/#ISAR_USE_CACHED_BASE_REPO ?= "1"/g' conf/local.conf
    sed -i -e 's/^BB_NO_NETWORK/#BB_NO_NETWORK/g' conf/local.conf
fi

# Start cross build for the defined set of configurations
sed -i -e 's/ISAR_CROSS_COMPILE ?= "0"/ISAR_CROSS_COMPILE ?= "1"/g' conf/local.conf
bitbake $BB_ARGS $CROSS_TARGETS_SET
while [ -e bitbake.sock ]; do sleep 1; done
if bitbake $BB_ARGS $CROSS_TARGETS_SET_BULLSEYE; then
    echo "bullseye cross: PASSED"
else
    echo "bullseye cross: KFAIL"
fi
# In addition test SDK creation
bitbake $BB_ARGS -c do_populate_sdk mc:qemuarm-stretch:isar-image-base
while [ -e bitbake.sock ]; do sleep 1; done

if [ -z "$FAST_BUILD" ]; then
    # Cleanup and disable cross build
    sudo rm -rf tmp
    sed -i -e 's/ISAR_CROSS_COMPILE ?= "1"/ISAR_CROSS_COMPILE ?= "0"/g' conf/local.conf
    bitbake $BB_ARGS $TARGETS_SET
    while [ -e bitbake.sock ]; do sleep 1; done

    if bitbake $BB_ARGS $TARGETS_SET_BULLSEYE; then
        echo "bullseye: PASSED"
    else
	echo "bullseye: KFAIL"
    fi
    while [ -e bitbake.sock ]; do sleep 1; done
fi

cp -a "${ISARROOT}/meta/classes/dpkg-base.bbclass" "${ISARROOT}/meta/classes/dpkg-base.bbclass.ci-backup"
echo -e "do_fetch_append() {\n\n}" >> "${ISARROOT}/meta/classes/dpkg-base.bbclass"

bitbake $BB_ARGS mc:qemuamd64-stretch:isar-image-base

mv "${ISARROOT}/meta/classes/dpkg-base.bbclass.ci-backup" "${ISARROOT}/meta/classes/dpkg-base.bbclass"
