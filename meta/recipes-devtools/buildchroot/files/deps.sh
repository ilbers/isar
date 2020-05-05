#!/bin/bash
#
# This software is a part of ISAR.
# Copyright (C) 2015-2017 ilbers GmbH
# Copyright (c) 2018 Siemens AG

source /isar/common.sh

# Install command to be used by mk-build-deps
# Notes:
#   1) everything before the -y switch is unchanged from the defaults
#   2) we add -y to go non-interactive
#   3) downgrades shall be allowed in case a package recipe was changed
install_cmd="apt-get -o Debug::pkgProblemResolver=yes --no-install-recommends \
    -y --allow-downgrades $3"

if [ "$3" != "--download-only" ]; then
    # Make sure that we have latest isar-apt content.
    # Options meaning:
    #   Dir::Etc::SourceList - specifies which source to be used
    #   Dir::Etc::SourceParts - disables looking for the other sources
    #   APT::Get::List-Cleanup - do not erase obsolete packages list for
    #                            upstream in '/var/lib/apt/lists'
    apt-get update \
        -o Dir::Etc::SourceList="sources.list.d/isar-apt.list" \
        -o Dir::Etc::SourceParts="-" \
        -o APT::Get::List-Cleanup="0"
fi

# Do not set an architecture when building only 'all' (generic) packages.
# This can avoid unneeded cross-build issues.
if ! grep "^Architecture:" debian/control | grep -qv "all"; then
    set_arch=""
fi

# Install all build deps
if [ "$3" = "--download-only" ]; then
    # this will not return 0 even when it worked
    mk-build-deps $set_arch -t "${install_cmd}" -i -r debian/control &> \
        mk-build-deps.output || true
    cat mk-build-deps.output
    # we assume success when we find this
    grep "mk-build-deps: Unable to install all build-dep packages" mk-build-deps.output
    rm -f mk-build-deps.output
else
    mk-build-deps $set_arch -t "${install_cmd}" -i -r debian/control

    # Upgrade any already installed packages in case we are partially rebuilding
    apt-get upgrade -y --allow-downgrades
fi
