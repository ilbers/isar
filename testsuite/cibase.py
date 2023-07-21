#!/usr/bin/env python3

import glob
import os
import re
import shutil
import tempfile
import time

from cibuilder import CIBuilder, isar_root
from avocado.utils import process

class CIBaseTest(CIBuilder):
    def perform_build_test(self, targets, **kwargs):
        self.configure(**kwargs)

        self.log.info('Starting build...')

        self.bitbake(targets, **kwargs)

    def perform_wic_partition_test(self, targets, wic_deploy_parts, **kwargs):
        self.configure(wic_deploy_parts=wic_deploy_parts, **kwargs)
        self.bitbake(targets, **kwargs)

        partition_files = set(glob.glob(f'{self.build_dir}/tmp/deploy/images/*/*.wic.p1'))
        if wic_deploy_parts and len(partition_files) == 0:
            self.fail('Found raw wic partitions in DEPLOY_DIR')
        if not wic_deploy_parts and len(partition_files) != 0:
            self.fail('Did not find raw wic partitions in DEPLOY_DIR')

    def perform_repro_test(self, targets, signed=False, **kwargs):
        gpg_pub_key = os.path.dirname(__file__) + '/keys/base-apt/test_pub.key'
        gpg_priv_key = os.path.dirname(__file__) + '/keys/base-apt/test_priv.key'

        self.configure(gpg_pub_key=gpg_pub_key if signed else None, sstate_dir="", **kwargs)

        os.chdir(self.build_dir)

        os.environ['GNUPGHOME'] = gnupg_home = tempfile.mkdtemp()
        result = process.run('gpg --import %s %s' % (gpg_pub_key, gpg_priv_key))

        if result.exit_status:
            self.fail('GPG import failed')

        try:
            self.bitbake(targets, **kwargs)

            self.delete_from_build_dir('tmp')
            self.configure(gpg_pub_key=gpg_pub_key if signed else None, offline=True, sstate_dir="", **kwargs)

            self.bitbake(targets, **kwargs)

            # Disable use of cached base repository
            self.unconfigure()

            if not signed:
                # Try to build with changed configuration with no cleanup
                self.configure(**kwargs)
                self.bitbake(targets, **kwargs)

        finally:
            # Cleanup
            process.run('gpgconf --kill gpg-agent')
            shutil.rmtree(gnupg_home, True)

    def perform_ccache_test(self, targets, **kwargs):
        def ccache_stats(dir, field):
            # Look ccache source's 'src/core/Statistic.hpp' for field meanings
            count = 0
            for filename in glob.iglob(dir + '/**/stats', recursive=True):
                if os.path.isfile(filename):
                    with open(filename,'r') as file:
                        content = file.readlines()
                        if (field < len(content)):
                            count += int(content[field])
            return count

        self.configure(ccache=True, sstate_dir="", **kwargs)

        # Field that stores direct ccache hits
        direct_cache_hit = 22

        self.delete_from_build_dir('tmp')
        self.delete_from_build_dir('sstate-cache')
        self.delete_from_build_dir('ccache')

        self.log.info('Starting build and filling ccache dir...')
        self.bitbake(targets, **kwargs)
        hit1 = ccache_stats(self.build_dir + '/ccache', direct_cache_hit)
        self.log.info('Ccache hits 1: ' + str(hit1))

        self.delete_from_build_dir('tmp')
        self.delete_from_build_dir('sstate-cache')

        self.log.info('Starting build and using ccache dir...')
        self.bitbake(targets, **kwargs)
        hit2 = ccache_stats(self.build_dir + '/ccache', direct_cache_hit)
        self.log.info('Ccache hits 2: ' + str(hit2))

        if hit2 <= hit1:
            self.fail('Ccache was not used on second build')

        # Cleanup
        self.delete_from_build_dir('tmp')
        self.delete_from_build_dir('sstate-cache')
        self.delete_from_build_dir('ccache')
        self.unconfigure()

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

        self.configure(sstate=True, sstate_dir="", **kwargs)

        # Cleanup sstate and tmp before test
        self.delete_from_build_dir('sstate-cache')
        self.delete_from_build_dir('tmp')

        # Populate cache
        self.bitbake(image_target, **kwargs)

        # Check signature files for cachability issues like absolute paths in signatures
        result = process.run(f'{isar_root}/scripts/isar-sstate lint {self.build_dir}/sstate-cache '
                             f'--build-dir {self.build_dir} --sources-dir {isar_root}')
        if result.exit_status > 0:
            self.fail("Detected cachability issues")

        # Save contents of image deploy dir
        expected_files = set(glob.glob(f'{self.build_dir}/tmp/deploy/images/*/*'))

        # Rebuild image
        self.delete_from_build_dir('tmp')
        self.bitbake(image_target, **kwargs)
        if not all([
                check_executed_tasks('isar-bootstrap-target',
                    ['do_bootstrap_setscene', '!do_bootstrap']),
                check_executed_tasks('sbuild-chroot-target',
                    ['do_rootfs_install_setscene', '!do_rootfs_install']),
                check_executed_tasks('isar-image-base-*',
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
                check_executed_tasks('sbuild-chroot-target',
                    ['!do_sbuildchroot_deploy']),
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
                check_executed_tasks('sbuild-chroot-target',
                    ['do_rootfs_install_setscene', '!do_rootfs_install']),
                check_executed_tasks('hello',
                    ['do_fetch', 'do_dpkg_build']),
                # TODO: if we actually make a change to hello, then we could test
                #       that do_rootfs is executed. currently, hello is rebuilt,
                #       but its sstate sig/hash does not change.
                check_executed_tasks('isar-image-base-*',
                    ['do_rootfs_install_setscene', '!do_rootfs_install'])
            ]):
            self.fail("Failed rebuild package and image")
