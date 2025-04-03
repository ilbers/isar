#!/usr/bin/env python3
#
# This software is a part of ISAR.
# Copyright (C) 2024-2025 ilbers GmbH
#
# SPDX-License-Identifier: MIT

import os
import sys
import tarfile
import time

sys.path.append(os.path.join(os.path.dirname(__file__), '../bitbake/lib'))

import bb
import bb.tinfoil

isar_root = os.path.abspath(os.path.join(os.path.dirname(__file__), '..'))


class CIUtils:
    @staticmethod
    def getVars(*vars, target=None):
        def fixStream(stream):
            # fix stream objects to emulate _io.TextIOWrapper
            stream.isatty = lambda: False
            stream.fileno = lambda: False
            stream.encoding = sys.getdefaultencoding()

        sl = target is not None
        if not hasattr(sys.stdout, 'isatty'):
            fixStream(sys.stdout)
        if not hasattr(sys.stderr, 'isatty'):
            fixStream(sys.stderr)

        # wait until previous bitbake will be finished
        lockfile = os.path.join(os.getcwd(), 'bitbake.lock')
        checks = 0
        while os.path.exists(lockfile) and checks < 5:
            time.sleep(1)
            checks += 1

        with bb.tinfoil.Tinfoil(setup_logging=sl) as tinfoil:
            values = ()
            if target:
                tinfoil.prepare(quiet=2)
                d = tinfoil.parse_recipe(target)
                for var in vars:
                    values = values + (d.getVar(var, True) or '',)
            else:
                tinfoil.prepare(config_only=True, quiet=2)
                for var in vars:
                    values = values + (tinfoil.config_data.getVar(var) or '',)
            return values if len(values) > 1 else values[0]

    @staticmethod
    def get_tar_content(filename):
        try:
            tar = tarfile.open(filename)
            return tar.getnames()
        except Exception:
            return []

    @staticmethod
    def get_test_images():
        return ['isar-image-base', 'isar-image-ci']

    @staticmethod
    def get_targets():
        d = bb.data.init()
        d.setVar('BBPATH', os.path.join(isar_root, 'meta-isar'))
        d = bb.cookerdata.parse_config_file('conf/mc.conf', d, False)
        return d.getVar('BBMULTICONFIG').split()

    @staticmethod
    def gen_targets_yaml(fn='targets.yml'):
        targetsfile = os.path.join(os.path.dirname(__file__), 'data', fn)
        with open(targetsfile, 'w') as f:
            f.write('a: !mux\n')
            for target in CIUtils.get_targets():
                f.write(f'  {target}:\n    name: {target}\n')
            f.write('b: !mux\n')
            prefix = 'isar-image-'
            for image in CIUtils.get_test_images():
                nodename = image
                if image.startswith(prefix):
                    nodename = image[len(prefix):]
                f.write(f'  {nodename}:\n    image: {image}\n')
