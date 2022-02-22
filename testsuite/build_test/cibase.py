#!/usr/bin/env python3

import os
import re
import tempfile
import time

from cibuilder import CIBuilder
from avocado.utils import process

class CIBaseTest(CIBuilder):
    def perform_build_test(self, targets, **kwargs):
        self.configure(**kwargs)

        self.log.info('Starting build...')

        self.bitbake(targets, **kwargs)

    def perform_repro_test(self, targets, signed=False, **kwargs):
        gpg_pub_key = os.path.dirname(__file__) + '/../base-apt/test_pub.key'
        gpg_priv_key = os.path.dirname(__file__) + '/../base-apt/test_priv.key'

        self.configure(gpg_pub_key=gpg_pub_key if signed else None, **kwargs)

        os.chdir(self.build_dir)

        os.environ['GNUPGHOME'] = tempfile.mkdtemp()
        result = process.run('gpg --import %s %s' % (gpg_pub_key, gpg_priv_key))

        if result.exit_status:
            self.fail('GPG import failed')

        self.bitbake(targets, **kwargs)

        self.delete_from_build_dir('tmp')
        self.configure(gpg_pub_key=gpg_pub_key if signed else None, offline=True, **kwargs)

        self.bitbake(targets, **kwargs)

        # Disable use of cached base repository
        self.unconfigure()

        if not signed:
            # Try to build with changed configuration with no cleanup
            self.bitbake(targets, **kwargs)

        # Cleanup
        self.delete_from_build_dir('tmp')

    def perform_ccache_test(self, targets):
        build_dir, bb_args = self.prep('Isar ccache build', targets, 0, 0)

        self.deletetmp(build_dir)
        process.run('rm -rf ' + build_dir + '/ccache', sudo=True)

        self.delete_from_build_dir('tmp')
        self.delete_from_build_dir('ccache')

        self.log.info('Starting build and filling ccache dir...')
        start = time.time()
        self.bitbake(targets, **kwargs)
        first_time = time.time() - start
        self.log.info('Non-cached build: ' + str(round(first_time)) + 's')

        self.delete_from_build_dir('tmp')

        self.log.info('Starting build and using ccache dir...')
        start = time.time()
        self.bitbake(targets, **kwargs)
        second_time = time.time() - start
        self.log.info('Cached build: ' + str(round(second_time)) + 's')

        speedup_k = 1.1
        if first_time / second_time < speedup_k:
            self.fail('No speedup after rebuild with ccache')

        # Cleanup
        self.delete_from_build_dir('tmp')
        self.delete_from_build_dir('ccache')
