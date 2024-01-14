#
# Copyright (c) Siemens AG, 2024
#
# SPDX-License-Identifier: MIT
#
# DESCRIPTION
# This creates a hybrid DOS partition table for a GPT disk, adding the
# partition marked as bootable to that table. This is useful if the boot
# partition is different from the EFI partition so that bootimg-biosplusefi
# cannot be used. Implemented as bootloader source plugin.

import logging

from wic import WicError
from wic.pluginbase import SourcePlugin
from wic.misc import exec_native_cmd

logger = logging.getLogger('wic')

class HybridBoot(SourcePlugin):
    """
    Create hybrid partition table with a single bootable partition.
    """

    name = 'hybrid-boot'

    @classmethod
    def do_install_disk(cls, disk, disk_name, creator, workdir, oe_builddir,
                        bootimg_dir, kernel_dir, native_sysroot):
        for part in creator.parts:
            if part.active:
                break
        else:
            raise WicError("No active partition found")

        logger.info("Creating hybrid partition table, using partition %d as bootable DOS partition" % part.realnum)
        exec_native_cmd("sgdisk %s --hybrid %d:EE" % (disk.path, part.realnum), native_sysroot)
        exec_native_cmd("sfdisk --label-nested dos -A %s %d" % (disk.path, part.realnum), native_sysroot)
