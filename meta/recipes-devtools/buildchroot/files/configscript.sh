#!/bin/sh
#
# This software is a part of ISAR.
# Copyright (C) 2015-2018 ilbers GmbH

set -e

debconf-set-selections <<END
locales locales/locales_to_be_generated multiselect en_US.UTF-8 UTF-8
locales locales/default_environment_locale select en_US.UTF-8
END
