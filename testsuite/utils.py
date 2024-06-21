#!/usr/bin/env python3

import os
import sys
import tarfile
import time

sys.path.append(os.path.join(os.path.dirname(__file__), '../bitbake/lib'))

import bb
import bb.tinfoil


class CIUtils():
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
