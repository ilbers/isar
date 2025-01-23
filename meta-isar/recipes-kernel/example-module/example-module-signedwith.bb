# Example recipe for building a custom module
#
# This software is a part of ISAR.
# Copyright (c) Siemens AG, 2025
#
# SPDX-License-Identifier: MIT

require example-module.bb

DEPENDS += "module-signer-example"
DEBIAN_BUILD_DEPENDS .= ', module-signer-example'

DEB_BUILD_PROFILES += 'pkg.signwith'
SIGNATURE_CERTFILE = '/etc/sb-mok-keys/MOK/MOK.der'
SIGNATURE_SIGNWITH = '/usr/bin/sign-module.sh'
