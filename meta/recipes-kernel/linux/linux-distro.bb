# Distro kernel dummy package
#
# This software is a part of ISAR.
# Copyright (c) Siemens AG, 2018
#
# SPDX-License-Identifier: MIT

python() {
    if ("class-native" or "class-compat") in d.getVar("OVERRIDES").split(":"):
        return

    distro_kernels = d.getVar('DISTRO_KERNELS') or ""
    kernel_img_pkg = d.getVar('KERNEL_IMAGE_PKG')
    kernel_headers_pkg = d.getVar('KERNEL_HEADERS_PKG')

    for kernel in distro_kernels.split():
        for prefix in ['linux-image', 'linux-headers', 'linux-kbuild']:
            d.appendVar('PROVIDES', ' {}-{}'.format(prefix, kernel))
            d.appendVar('RPROVIDES', ' {}-{}'.format(prefix, kernel))
    if kernel_img_pkg:
        d.appendVar('PROVIDES', ' ' + kernel_img_pkg)
        d.appendVar('RPROVIDES', ' ' + kernel_img_pkg)
    if kernel_headers_pkg:
        d.appendVar('PROVIDES', ' ' + kernel_headers_pkg)
        d.appendVar('RPROVIDES', ' ' + kernel_headers_pkg)
}

inherit multiarch
