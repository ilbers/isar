# This software is a part of ISAR.
# Copyright (C) Siemens AG, 2023
#
# SPDX-License-Identifier: MIT

from bitbake import load_function
from rootfs import TemporaryRootfs

import os
import sys
import unittest
from unittest.mock import patch
from typing import Tuple

sys.path.append(os.path.join(os.path.dirname(__file__), '../../bitbake/lib'))

from bb import process
from bb.data_smart import DataSmart

file_name = 'meta/classes/image-account-extension.bbclass'
image_create_users = load_function(file_name, 'image_create_users')
image_create_groups = load_function(file_name, 'image_create_groups')


class TestImageAccountExtensionCommon(unittest.TestCase):
    def setup(self) -> Tuple[DataSmart, TemporaryRootfs]:
        rootfs = TemporaryRootfs()

        d = DataSmart()
        d.setVar('ROOTFSDIR', rootfs.path())

        return (d, rootfs)


class TestImageAccountExtensionImageCreateUsers(
    TestImageAccountExtensionCommon
):
    def setup(self, user_name: str) -> Tuple[DataSmart, TemporaryRootfs]:
        d, rootfs = super().setup()
        rootfs.create_file(
            '/etc/passwd', 'test:x:1000:1000::/home/test:/bin/sh'
        )
        d.setVar('USERS', user_name)
        return (d, rootfs)

    def test_new_user(self):
        test_user = 'new'
        d, rootfs = self.setup(test_user)
        # Make the list a bit clumsy to simulate appends and removals to that
        # var
        d.setVarFlag(f"USER_{test_user}", 'groups', 'dialout render  foo ')

        with patch.object(process, 'run') as run_mock:
            image_create_users(d)

        run_mock.assert_called_once_with(
            [
                'sudo',
                '-E',
                'chroot',
                rootfs.path(),
                '/usr/sbin/useradd',
                '--groups',
                'dialout,render,foo',
                test_user,
            ]
        )

    def test_existing_user_no_change(self):
        test_user = 'test'
        d, _ = self.setup(test_user)

        with patch.object(process, 'run') as run_mock:
            image_create_users(d)

        run_mock.assert_not_called()

    def test_existing_user_home_change(self):
        test_user = 'test'
        d, _ = self.setup(test_user)
        d.setVarFlag(f"USER_{test_user}", 'home', '/home/new_home')

        with patch.object(process, 'run') as run_mock:
            image_create_users(d)

        assert run_mock.call_count == 1
        assert run_mock.call_args[0][0][-5:] == [
            '/usr/sbin/usermod',
            '--home',
            '/home/new_home',
            '--move-home',
            'test',
        ]

    def test_deterministic_password(self):
        test_user = 'new'
        cleartext_password = 'test'
        d, _ = self.setup(test_user)

        d.setVarFlag(f"USER_{test_user}", 'flags', 'clear-text-password')
        d.setVarFlag(f"USER_{test_user}", 'password', cleartext_password)

        source_date_epoch = '1672427776'
        d.setVar('SOURCE_DATE_EPOCH', source_date_epoch)

        # openssl passwd -6 -salt $(echo "1672427776" | sha256sum -z | cut \
        #  -c 1-15) test
        encrypted_password = (
            '$6$eb2e2a12cccc88a$IuhgisFe5AKM5.VREKg8wIAcPSkaJDWBM1cMUsEjNZh2W'
            'a6BT2f5OFhqGTGpL4lFzHGN8oiwvAh0jFO1GhO3S.'
        )

        with patch.object(process, 'run') as run_mock:
            image_create_users(d)

        password_data = f"{test_user}:{encrypted_password}".encode()

        assert run_mock.call_count == 2
        assert run_mock.call_args[0][1] == password_data


class TestImageAccountExtensionImageCreateGroups(
    TestImageAccountExtensionCommon
):
    def setup(self, group_name: str) -> Tuple[DataSmart, TemporaryRootfs]:
        d, rootfs = super().setup()
        rootfs.create_file('/etc/group', 'test:x:1000:test')
        d.setVar('GROUPS', group_name)
        return (d, rootfs)

    def test_new_group(self):
        test_group = 'new'
        d, rootfs = self.setup(test_group)

        with patch.object(process, 'run') as run_mock:
            image_create_groups(d)

        run_mock.assert_called_once_with(
            [
                'sudo',
                '-E',
                'chroot',
                rootfs.path(),
                '/usr/sbin/groupadd',
                test_group,
            ]
        )

    def test_existing_group_no_change(self):
        test_group = 'test'
        d, _ = self.setup(test_group)

        with patch.object(process, 'run') as run_mock:
            image_create_groups(d)

        run_mock.assert_not_called()

    def test_existing_group_id_change(self):
        test_group = 'test'
        d, rootfs = self.setup(test_group)
        d.setVarFlag(f"GROUP_{test_group}", 'gid', '1005')

        with patch.object(process, 'run') as run_mock:
            image_create_groups(d)

        run_mock.assert_called_once_with(
            [
                'sudo',
                '-E',
                'chroot',
                rootfs.path(),
                '/usr/sbin/groupmod',
                '--gid',
                '1005',
                test_group,
            ]
        )

    def test_new_group_system_flag(self):
        test_group = 'new'
        d, _ = self.setup(test_group)
        d.setVarFlag(f"GROUP_{test_group}", 'flags', 'system')

        with patch.object(process, 'run') as run_mock:
            image_create_groups(d)

        assert run_mock.call_count == 1
        assert '--system' in run_mock.call_args[0][0]

    def test_existing_group_no_system_flag(self):
        test_group = 'test'
        d, _ = self.setup(test_group)
        d.setVarFlag(f"GROUP_{test_group}", 'flags', 'system')
        d.setVarFlag(f"GROUP_{test_group}", 'gid', '1005')

        with patch.object(process, 'run') as run_mock:
            image_create_groups(d)

        assert run_mock.call_count == 1
        assert '--system' not in run_mock.call_args[0][0]


if __name__ == '__main__':
    unittest.main()
