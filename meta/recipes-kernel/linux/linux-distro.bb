# Distro kernel dummy package
#
# This software is a part of ISAR.
# Copyright (c) Siemens AG, 2018
#
# SPDX-License-Identifier: MIT

python() {
    distro_kernels = d.getVar('DISTRO_KERNELS', True) or ""
    for kernel in distro_kernels.split():
        d.appendVar('PROVIDES', ' linux-image-' + kernel)
        d.appendVar('PROVIDES', ' linux-headers-' + kernel)
}
