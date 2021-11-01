#!/bin/bash
#
# This software is a part of ISAR.
# Copyright (C) 2015-2017 ilbers GmbH
# Copyright (c) 2018 Siemens AG

source /isar/common.sh

# If autotools files have been created, update their timestamp to
# prevent them from being regenerated
for i in configure aclocal.m4 Makefile.am Makefile.in; do
    if [ -f "${i}" ]; then
        touch "${i}"
    fi
done

if [ "$use_ccache" == "1" ]; then
    export CCACHE_DIR=/ccache
    export PATH=/usr/lib/ccache:$PATH
fi

${GBP_PREFIX}dpkg-buildpackage -a$target_arch -d --source-option=-I
