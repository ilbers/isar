#!/usr/bin/env python3

import glob
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

    def perform_sstate_test(self, image_target, package_target, **kwargs):
        def check_executed_tasks(target, expected):
            taskorder_file = glob.glob(f'{self.build_dir}/tmp/work/*/{target}/*/temp/log.task_order')
            try:
                with open(taskorder_file[0], 'r') as f:
                    tasks = [l.split()[0] for l in f.readlines()]
            except (FileNotFoundError, IndexError):
                tasks = []
            if expected is None:
                # require that no tasks were executed
                return len(tasks) == 0
            for e in expected:
                should_run = True
                if e.startswith('!'):
                    should_run = False
                    e = e[1:]
                if should_run != (e in tasks):
                    self.log.error(f"{target}: executed tasks {str(tasks)} did not match expected {str(expected)}")
                    return False
            return True

        self.configure(sstate=True, **kwargs)

        # Cleanup sstate and tmp before test
        self.delete_from_build_dir('sstate-cache')
        self.delete_from_build_dir('tmp')

        # Populate cache
        self.bitbake(image_target, **kwargs)

        # Save contents of image deploy dir
        expected_files = set(glob.glob(f'{self.build_dir}/tmp/deploy/images/*/*'))

        # Rebuild image
        self.delete_from_build_dir('tmp')
        self.bitbake(image_target, **kwargs)
        if not all([
                check_executed_tasks('isar-bootstrap-target',
                    ['do_bootstrap_setscene', '!do_bootstrap']),
                check_executed_tasks('buildchroot-target',
                    ['do_rootfs_install_setscene', '!do_rootfs_install']),
                check_executed_tasks('isar-image-base-*-wic-img',
                    ['do_rootfs_install_setscene', '!do_rootfs_install'])
            ]):
            self.fail("Failed rebuild image")

        # Verify content of image deploy dir
        deployed_files = set(glob.glob(f'{self.build_dir}/tmp/deploy/images/*/*'))
        if not deployed_files == expected_files:
            if len(expected_files - deployed_files) > 0:
                self.log.error(f"{target}: files missing from deploy dir after rebuild with sstate cache:"
                               f"{expected_files - deployed_files}")
            if len(deployed_files - expected_files) > 0:
                self.log.error(f"{target}: additional files in deploy dir after rebuild with sstate cache:"
                               f"{deployed_files - expected_files}")
            self.fail("Failed rebuild image")

        # Rebuild single package
        self.delete_from_build_dir('tmp')
        self.bitbake(package_target, **kwargs)
        if not all([
                check_executed_tasks('isar-bootstrap-target',
                    ['do_bootstrap_setscene']),
                check_executed_tasks('buildchroot-target',
                    ['!do_buildchroot_deploy']),
                check_executed_tasks('hello',
                    ['do_dpkg_build_setscene', 'do_deploy_deb', '!do_dpkg_build'])
            ]):
            self.fail("Failed rebuild single package")

        # Rebuild package and image
        self.delete_from_build_dir('tmp')
        process.run(f'find {self.build_dir}/sstate-cache/ -name sstate:hello:* -delete')
        self.bitbake(image_target, **kwargs)
        if not all([
                check_executed_tasks('isar-bootstrap-target',
                    ['do_bootstrap_setscene', '!do_bootstrap']),
                check_executed_tasks('buildchroot-target',
                    ['do_rootfs_install_setscene', '!do_rootfs_install']),
                check_executed_tasks('hello',
                    ['do_fetch', 'do_dpkg_build']),
                # TODO: if we actually make a change to hello, then we could test
                #       that do_rootfs is executed. currently, hello is rebuilt,
                #       but its sstate sig/hash does not change.
                check_executed_tasks('isar-image-base-*-wic-img',
                    ['do_rootfs_install_setscene', '!do_rootfs_install'])
            ]):
            self.fail("Failed rebuild package and image")
