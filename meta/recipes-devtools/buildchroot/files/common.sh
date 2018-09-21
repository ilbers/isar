#!/bin/bash
#
# This software is a part of ISAR.
# Copyright (C) 2015-2017 ilbers GmbH
# Copyright (c) 2018 Siemens AG

set -e
printenv | grep -q BB_VERBOSE_LOGS && set -x

# Create human-readable names
target_arch=$2

# Notes:
#   mk-build-deps for jessie and jtretch has different parameter name to specify
#   host architecture.
debian_version=$(cut -c1 /etc/debian_version)
if [ $(($debian_version)) -ge 9 ]; then
    set_arch="--host-arch $target_arch"
else
    set_arch="-a $target_arch"
fi

# Go to build directory
cd $1

# To avoid Perl locale warnings:
export LC_ALL=C
export LANG=C
export LANGUAGE=C
