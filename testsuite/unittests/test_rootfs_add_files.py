# This software is a part of Isar.
# Copyright (C) Siemens AG, 2026
#
# SPDX-License-Identifier: MIT

from rootfs import TemporaryRootfs

import os
import sys
import unittest
from unittest.mock import patch
from typing import Tuple

sys.path.append(os.path.join(os.path.dirname(__file__), '../../bitbake/lib'))

from bb import process
from bb.build import exec_func
from bb.data_smart import DataSmart
from bb.data import init
from bb.parse import handle

file_name = 'meta/classes-recipe/rootfs-add-files.bbclass'


class TestRootfsAddFiles(unittest.TestCase):
    def assert_remove_targets_rootfs(self, run_mock, rootfs_file):
        command = run_mock.call_args_list[0].args[0]
        if isinstance(command, str):
            command = command.split()
        self.assertEqual(
            command[-3:], ['/usr/bin/rm', '-f', rootfs_file],
            'Expected the existing destination to be removed from ROOTFSDIR.',
        )

    def setup(self, chroot_mode: str,
              destination: str = 'install/payload'
              ) -> Tuple[DataSmart, TemporaryRootfs]:
        rootfs = TemporaryRootfs()
        rootfs.create_file('/source', 'payload')
        rootfs.create_file('/install/payload', 'old payload')

        d = handle(
            os.path.join(os.path.dirname(__file__), '../..', file_name),
            init(),
        )
        d.setVar('T', f'{rootfs.path()}/temp')
        d.setVar('ROOTFSDIR', rootfs.path())
        d.setVar('ROOTFS_ADDITIONAL_FILES', 'payload')
        d.setVar('RUN_PRIVILEGED_CMD', 'unshare --mount --user'
                 if chroot_mode == 'unshare' else 'sudo -E')
        d.setVar('ISAR_CHROOT_MODE', chroot_mode)
        d.setVarFlag('ROOTFS_ADDITIONAL_FILE_payload', 'source',
                     f'{rootfs.path()}/source')
        d.setVarFlag('ROOTFS_ADDITIONAL_FILE_payload', 'destination',
                     destination)
        return (d, rootfs)

    def test_replace_existing_file(self):
        for destination in ('install/payload', '/install/payload'):
            with self.subTest(destination=destination):
                d, rootfs = self.setup('schroot', destination)
                rootfs_file = f'{rootfs.path()}/{destination}'

                with patch.object(process, 'run') as run_mock:
                    exec_func('rootfs_add_files', d)

                self.assert_remove_targets_rootfs(run_mock, rootfs_file)

    def test_replace_existing_file_unshare(self):
        d, rootfs = self.setup('unshare')
        rootfs_file = f'{rootfs.path()}/install/payload'

        with patch.object(process, 'run') as run_mock:
            exec_func('rootfs_add_files', d)

        self.assert_remove_targets_rootfs(run_mock, rootfs_file)


if __name__ == '__main__':
    unittest.main()
