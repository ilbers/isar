#!/bin/bash
#
# This software is a part of ISAR.
# Copyright (C) 2015-2017 ilbers GmbH
# Copyright (c) 2018 Siemens AG

set -e
printenv | grep -q BB_VERBOSE_LOGS && set -x

# assert we are either "root:root" or "builder:<gid of builder>"
if ([ "$(id -un)" != "builder" ] || [ "$(id -g)" != "$(id -g builder)" ]) &&
   ([ "$(id -un)" != "root"    ] || [ "$(id -gn)" != "root"    ]); then
    echo "This script can only be run as root:root or builder:<gid of builder>!" >&2
    echo "(Currently running as $(id -un)($(id -u)):$(id -gn)($(id -g)))" >&2
    exit 1
fi

# Create human-readable names
target_arch=$2

set_arch="--host-arch $target_arch"

# Go to build directory
cd "$1"

# To avoid Perl locale warnings:
export LC_ALL=C
export LANG=C
export LANGUAGE=C

# allow for changes to the PATH variable
export PATH=$PATH_PREPEND:$PATH
