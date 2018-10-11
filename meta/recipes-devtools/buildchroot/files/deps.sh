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
install_cmd="apt-get -o Debug::pkgProblemResolver=yes --no-install-recommends -y --allow-unauthenticated"

# Make sure that we have latest isar-apt content.
# Options meaning:
#   Dir::Etc::sourcelist - specifies which source to be used
#   Dir::Etc::sourceparts - disables looking for the other sources
#   APT::Get::List-Cleanup - do not erase obsolete packages list for
#                            upstream in '/var/lib/apt/lists'
apt-get update \
    -o Dir::Etc::sourcelist="sources.list.d/isar-apt.list" \
    -o Dir::Etc::sourceparts="-" \
    -o APT::Get::List-Cleanup="0"

# Install all build deps
mk-build-deps $set_arch -t "${install_cmd}" -i -r debian/control
