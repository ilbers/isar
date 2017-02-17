#!/bin/bash
#
# This software is a part of ISAR.
# Copyright (C) 2015-2017 ilbers GmbH

# Go to build directory
cd $1

# Get list of dependencies manually. The package is not in apt, so no apt-get
# build-dep. dpkg-checkbuilddeps output contains version information and isn't
# directly suitable for apt-get install.
DEPS=`perl -ne 'next if /^#/; $p=(s/^Build-Depends:\s*/ / or (/^ / and $p)); s/,|\n|\([^)]+\)|\[[^]]+\]//mg; print if $p' < debian/control`

# Install deps
apt-get install -y $DEPS

# If autotools files have been created, update their timestamp to
# prevent them from being regenerated
for i in configure aclocal.m4 Makefile.am Makefile.in; do
    if [ -f "${i}" ]; then
        touch "${i}"
    fi
done

# Build the package
dpkg-buildpackage
