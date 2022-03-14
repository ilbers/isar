#
# Copyright (c) Siemens AG, 2021
#
# SPDX-License-Identifier: MIT
#
# DESCRIPTION
# This implements a few utility functions to be used in isar-specific plugins.

import os

from wic import WicError

def isar_populate_boot_cmd(rootfs_dir, hdddir):
    # copy all files from rootfs/boot into boot partition
    # no not copy symlinks (ubuntu places them here) because targetfs is fat
    return "find %s/boot -type f -exec cp -a {} %s ;" % (rootfs_dir, hdddir)

def isar_get_filenames(rootfs_dir):
    # figure out the real filename in /boot by following debian symlinks
    for kernel_symlink in ["vmlinuz", "vmlinux" ]:
        kernel_file_abs = os.path.join(rootfs_dir, kernel_symlink)
        if os.path.isfile(kernel_file_abs):
            break
        # in ubuntu those symlinks could be in /boot
        kernel_file_abs = os.path.join(rootfs_dir, "boot", kernel_symlink)
        if os.path.isfile(kernel_file_abs):
            break

    kernel = os.path.basename(os.path.realpath(kernel_file_abs))
    initrd =  "initrd.img"
    kernel_parts = kernel.split("-")
    kernel_suffix = "-".join(kernel_parts[1:])
    if kernel_suffix:
        initrd += "-%s" % kernel_suffix

    if not os.path.isfile(os.path.join(rootfs_dir, "boot", kernel)):
        raise WicError("kernel %s not found" % (os.path.join(rootfs_dir, "boot", kernel)))
    if not os.path.isfile(os.path.join(rootfs_dir, "boot", initrd)):
        raise WicError("initrd %s not found" % (os.path.join(rootfs_dir, "boot", initrd)))

    return kernel, initrd
