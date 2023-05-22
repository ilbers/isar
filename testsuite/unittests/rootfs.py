# This software is a part of ISAR.
# Copyright (C) Siemens AG, 2023
#
# SPDX-License-Identifier: MIT

import tempfile
import pathlib
import shutil
import atexit

temp_dirs = []


class TemporaryRootfs:
    """ A temporary rootfs folder that will be removed after the testrun. """

    def __init__(self):
        self._rootfs_path = tempfile.mkdtemp()
        temp_dirs.append(self._rootfs_path)

    def path(self) -> str:
        return self._rootfs_path

    def create_file(self, path: str, content: str) -> None:
        """ Create a file with the given content.

        Args:
            path (str): The path to the file e.g. `/etc/hostname`.
            content (str): The content of the file e.g. `my_special_host`

        Returns:
            None
        """
        pathlib.Path(self._rootfs_path +
                     path).parent.mkdir(parents=True, exist_ok=True)
        with open(self._rootfs_path + path, 'w') as file:
            file.write(content)


def cleanup():
    for temp_dir in temp_dirs:
        shutil.rmtree(temp_dir)


atexit.register(cleanup)
