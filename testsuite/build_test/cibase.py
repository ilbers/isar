#!/usr/bin/env python3

import os
import re
import tempfile
import time

from cibuilder import CIBuilder
from avocado.utils import process

isar_root = os.path.dirname(__file__) + '/../..'

class CIBaseTest(CIBuilder):

    def prep(self, testname, targets, cross, debsrc_cache):
        build_dir = self.params.get('build_dir', default=isar_root + '/build')
        build_dir = os.path.realpath(build_dir)
        quiet = int(self.params.get('quiet', default=0))
        bitbake_args = '-v'

        if quiet:
            bitbake_args = ''

        self.log.info('===================================================')
        self.log.info('Running ' + testname + ' test for:')
        self.log.info(targets)
        self.log.info('Isar build folder is: ' + build_dir)
        self.log.info('===================================================')

        self.init(build_dir)
        self.confprepare(build_dir, 1, cross, debsrc_cache)

        return build_dir, bitbake_args;

    def perform_build_test(self, targets, cross, bitbake_cmd):
        build_dir, bb_args = self.prep('Isar build', targets, cross, 1)

        self.log.info('Starting build...')

        self.bitbake(build_dir, targets, bitbake_cmd, bb_args)

    def perform_repro_test(self, targets, signed):
        cross = int(self.params.get('cross', default=0))
        build_dir, bb_args = self.prep('repro Isar build', targets, cross, 0)

        gpg_pub_key = os.path.dirname(__file__) + '/../base-apt/test_pub.key'
        gpg_priv_key = os.path.dirname(__file__) + '/../base-apt/test_priv.key'

        if signed:
            with open(build_dir + '/conf/ci_build.conf', 'a') as file:
                # Enable use of signed cached base repository
                file.write('BASE_REPO_KEY="file://' + gpg_pub_key + '"\n')

        os.chdir(build_dir)

        os.environ['GNUPGHOME'] = tempfile.mkdtemp()
        result = process.run('gpg --import %s %s' % (gpg_pub_key, gpg_priv_key))

        if result.exit_status:
            self.fail('GPG import failed')

        self.bitbake(build_dir, targets, None, bb_args)

        self.deletetmp(build_dir)
        with open(build_dir + '/conf/ci_build.conf', 'a') as file:
            file.write('ISAR_USE_CACHED_BASE_REPO = "1"\n')
            file.write('BB_NO_NETWORK = "1"\n')

        self.bitbake(build_dir, targets, None, bb_args)

        # Disable use of cached base repository
        self.confcleanup(build_dir)

        if not signed:
            # Try to build with changed configuration with no cleanup
            self.bitbake(build_dir, targets, None, bb_args)

        # Cleanup
        self.deletetmp(build_dir)

    def perform_wic_test(self, targets, wks_path, wic_path):
        cross = int(self.params.get('cross', default=0))
        build_dir, bb_args = self.prep('WIC exclude build', targets, cross, 1)

        layerdir_isar = self.getlayerdir('isar')

        wks_file = layerdir_isar + wks_path
        wic_img = build_dir + wic_path

        if not os.path.isfile(wic_img):
            self.fail('No build started before: ' + wic_img + ' not exist')

        self.backupfile(wks_file)
        self.backupmove(wic_img)

        with open(wks_file, 'r') as file:
            lines = file.readlines()
        with open(wks_file, 'w') as file:
            for line in lines:
                file.write(re.sub(r'part \/ ', 'part \/ --exclude-path usr ',
                                  line))

        try:
            self.bitbake(build_dir, targets, None, bb_args)
        finally:
            self.restorefile(wks_file)

        self.restorefile(wic_img)

    def perform_container_test(self, targets, bitbake_cmd):
        cross = int(self.params.get('cross', default=0))
        build_dir, bb_args = self.prep('Isar Container', targets, cross, 1)

        self.containerprep(build_dir)

        self.bitbake(build_dir, targets, bitbake_cmd, bb_args)


    def perform_ccache_test(self, targets):
        build_dir, bb_args = self.prep('Isar ccache build', targets, 0, 0)

        self.deletetmp(build_dir)
        process.run('rm -rf ' + build_dir + '/ccache', sudo=True)

        with open(build_dir + '/conf/ci_build.conf', 'a') as file:
            file.write('USE_CCACHE = "1"\n')
            file.write('CCACHE_TOP_DIR = "${TOPDIR}/ccache"')

        self.log.info('Starting build and filling ccache dir...')
        start = time.time()
        self.bitbake(build_dir, targets, None, bb_args)
        first_time = time.time() - start
        self.log.info('Non-cached build: ' + str(round(first_time)) + 's')

        self.deletetmp(build_dir)

        self.log.info('Starting build and using ccache dir...')
        start = time.time()
        self.bitbake(build_dir, targets, None, bb_args)
        second_time = time.time() - start
        self.log.info('Cached build: ' + str(round(second_time)) + 's')

        speedup_k = 1.1
        if first_time / second_time < speedup_k:
            self.fail('No speedup after rebuild with ccache')

        # Cleanup
        self.deletetmp(build_dir)
        process.run('rm -rf ' + build_dir + '/ccache', sudo=True)
