#!/bin/bash
#
# This software is a part of ISAR.
# Copyright (C) 2015-2017 ilbers GmbH

# Go to build directory
cd $1

# Install command to be used by mk-build-deps
# Notes:
#   1) everything before the -y switch is unchanged from the defaults
#   2) we add -y to go non-interactive
install_cmd="apt-get -o Debug::pkgProblemResolver=yes --no-install-recommends -y"

# Install all build deps
mk-build-deps -t "${install_cmd}" -i -r debian/control

# If autotools files have been created, update their timestamp to
# prevent them from being regenerated
for i in configure aclocal.m4 Makefile.am Makefile.in; do
    if [ -f "${i}" ]; then
        touch "${i}"
    fi
done

# Build the package
LC_ALL=C LANG=C dpkg-buildpackage
