#!/bin/bash

# Go to build directory
cd $1

# Get list of dependencies
DEPS=`perl -ne 'next if /^#/; $p=(s/^Build-Depends:\s*/ / or (/^ / and $p)); s/,|\n|\([^)]+\)//mg; print if $p' < debian/control`

# Install deps
apt-get install $DEPS

# Build the package
dpkg-buildpackage
