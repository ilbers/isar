# Example recipe for building a custom module
#
# This software is a part of ISAR.
# Copyright (c) Siemens AG, 2022
#
# SPDX-License-Identifier: MIT

require example-module.bb

DEPENDS += "sb-mok-keys"
DEBIAN_BUILD_DEPENDS .= ', sb-mok-keys'
DEB_BUILD_PROFILES += 'pkg.sign'
SIGNATURE_KEYFILE  = '/etc/sb-mok-keys/MOK/MOK.priv'
SIGNATURE_CERTFILE = '/etc/sb-mok-keys/MOK/MOK.der'
