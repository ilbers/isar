# Example recipe for building a custom module
#
# This software is a part of ISAR.
# Copyright (c) Siemens AG, 2018
#
# SPDX-License-Identifier: MIT

# Cross-compilation is not supported for the default Debian kernels.
# For example, package with kernel headers for ARM:
#   linux-headers-armmp
# has hard dependencies from linux-compiler-gcc-4.8-arm, what
# conflicts with the host binaries.
python() {
    if d.getVar('KERNEL_NAME') in [
        'armmp',
        'arm64',
        'rpi-rpfv',
        'amd64',
        '686-pae',
        '4kc-malta',
        'riscv64',
    ]:
        d.setVar('ISAR_CROSS_COMPILE', '0')
}

require recipes-kernel/linux-module/module.inc

SRC_URI += "file://src"

S = "${WORKDIR}/src"

AUTOLOAD = "example-module"
