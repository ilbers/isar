# This software is a part of Isar.
# Copyright (C) Siemens AG, 2026
#
# SPDX-License-Identifier: MIT

import multiprocessing
import os
import sys
import tempfile
import unittest
import uuid
from pathlib import Path

root = Path(__file__).resolve().parents[2]
sys.path.extend([
    str(root / 'bitbake/lib'),
    str(root / 'meta/lib'),
])

import bb
import bb.build
import bb.data
import bb.utils
from bb.parse import handle


data = bb.data.init()
data.setVar('BBPATH', f'{root}/meta:{root}/bitbake')
data.setVar('__bbclasstype', 'global')
parsed = handle(str(root / 'meta/classes-global/base.bbclass'), data)
namespace = {'bb': bb, 'os': os}
exec(parsed['calculate_build_uuid'], namespace)
exec(parsed['clear_build_uuid'], namespace)
calculate_build_uuid = namespace['calculate_build_uuid']
clear_build_uuid = namespace['clear_build_uuid']


def calculate_in_worker(persistent_dir, start, results):
    data = bb.data.init()
    data.setVar('PERSISTENT_DIR', persistent_dir)
    start.wait()
    results.put(calculate_build_uuid(data))


class TestBuildUUID(unittest.TestCase):
    def setUp(self):
        directory = tempfile.TemporaryDirectory()
        self.addCleanup(directory.cleanup)
        self.persistent_dir = os.path.join(directory.name, 'cache')
        self.data = bb.data.init()
        self.data.setVar('PERSISTENT_DIR', self.persistent_dir)

    def test_uuid_is_reused_across_calls_and_multiconfigs(self):
        build_uuid = calculate_build_uuid(self.data)
        self.assertEqual(str(uuid.UUID(build_uuid)), build_uuid)
        self.assertEqual(calculate_build_uuid(self.data), build_uuid)
        other_config = self.data.createCopy()
        other_config.setVar('BB_CURRENT_MC', 'other')
        self.assertEqual(calculate_build_uuid(other_config), build_uuid)
        clear_build_uuid(self.data)
        self.assertNotEqual(calculate_build_uuid(self.data), build_uuid)

    def test_completion_resets_only_default_multiconfig(self):
        data = handle(
            str(root / 'meta/classes-global/isar-events.bbclass'), self.data
        )
        data.setVar('TMPDIR', self.persistent_dir)
        data.setVar('T', os.path.join(self.persistent_dir, 'temp'))
        for multiconfig, resets_uuid in [
            ('', True), ('default', True), ('other', False)
        ]:
            with self.subTest(multiconfig=multiconfig):
                build_uuid = calculate_build_uuid(data)
                data.setVar('BB_CURRENT_MC', multiconfig)
                bb.build.exec_func('build_completed', data)
                self.assertEqual(
                    calculate_build_uuid(data) != build_uuid, resets_uuid
                )

    def test_concurrent_workers_share_uuid(self):
        context = multiprocessing.get_context('fork')
        start = context.Event()
        results = context.Queue()
        workers = [
            context.Process(
                target=calculate_in_worker,
                args=(self.persistent_dir, start, results),
            )
            for _ in range(8)
        ]
        try:
            for worker in workers:
                worker.start()
            start.set()
            values = [results.get(timeout=15) for worker in workers]
            for worker in workers:
                worker.join(timeout=15)
                self.assertEqual(worker.exitcode, 0)
            self.assertEqual(len(set(values)), 1)
            self.assertEqual(values[0], calculate_build_uuid(self.data))
        finally:
            for worker in workers:
                if worker.is_alive():
                    worker.terminate()
                worker.join(timeout=15)
            results.close()
            results.join_thread()
