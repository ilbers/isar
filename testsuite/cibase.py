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
            self.move_in_build_dir('tmp', 'tmp_before_repro')
            self.bitbake(targets, **kwargs)

            self.move_in_build_dir('tmp', 'tmp_middle_repro_%s' % ('signed' if signed else 'unsigned'))
            
            os.makedirs(f"{self.build_dir}/tmp/deploy/")
            self.move_in_build_dir('tmp_middle_repro_%s/deploy/base-apt' % ('signed' if signed else 'unsigned'), 'tmp/deploy/base-apt')
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

        self.move_in_build_dir('tmp', 'tmp_before_ccache')
        self.delete_from_build_dir('sstate-cache')
        self.delete_from_build_dir('ccache')

        self.log.info('Starting build and filling ccache dir...')
        self.bitbake(targets, **kwargs)
        hit1 = ccache_stats(self.build_dir + '/ccache', direct_cache_hit)
        self.log.info('Ccache hits 1: ' + str(hit1))

        self.move_in_build_dir('tmp', 'tmp_middle_ccache')
        self.delete_from_build_dir('sstate-cache')

        self.log.info('Starting build and using ccache dir...')
        self.bitbake(targets, **kwargs)
        hit2 = ccache_stats(self.build_dir + '/ccache', direct_cache_hit)
        self.log.info('Ccache hits 2: ' + str(hit2))

        if hit2 <= hit1:
            self.fail('Ccache was not used on second build')

        # Cleanup
        self.move_in_build_dir('tmp', 'tmp_after_ccache')
        self.delete_from_build_dir('sstate-cache')
        self.delete_from_build_dir('ccache')
        self.unconfigure()

    def perform_sstate_populate(self, image_target, **kwargs):
        # Use a different isar root for populating sstate cache
        isar_sstate = f"{isar_root}/isar-sstate"
        os.makedirs(isar_sstate)
        process.run(f'git --work-tree={isar_sstate} checkout HEAD -- .')

        self.init('../build-sstate', isar_dir=isar_sstate)
        self.configure(sstate=True, sstate_dir="", **kwargs)

        # Cleanup sstate and tmp before test
        self.delete_from_build_dir('sstate-cache')
        self.move_in_build_dir('tmp', 'tmp_before_sstate_populate')

        # Populate cache
        self.bitbake(image_target, **kwargs)

        # Remove isar configuration so the the following test creates a new one
        self.delete_from_build_dir('conf')

    def perform_signature_lint(self, targets, verbose=False, sources_dir=isar_root,
                               excluded_tasks=None, **kwargs):
        """Generate signature data for target(s) and check for cachability issues."""
        self.configure(**kwargs)
        self.move_in_build_dir("tmp", "tmp_before_sstate")
        self.bitbake(targets, sig_handler="none")

        verbose_arg = "--verbose" if verbose else ""
        excluded_arg = f"--excluded-tasks {','.join(excluded_tasks)}" if excluded_tasks else ""
        cmd = f"{isar_root}/scripts/isar-sstate lint --lint-stamps {self.build_dir}/tmp/stamps " \
              f"--build-dir {self.build_dir} --sources-dir {sources_dir} {verbose_arg} {excluded_arg}"
        self.log.info(f"Running: {cmd}")
        exit_status, output = process.getstatusoutput(cmd, ignore_status=True)
        if exit_status > 0:
            ansi_escape = re.compile(r'\x1B(?:[@-Z\\-_]|\[[0-?]*[ -/]*[@-~])')
            for line in output.splitlines():
                self.log.error(ansi_escape.sub('', line))
            self.fail("Detected cachability issues")

    def perform_sstate_test(self, image_target, package_target, **kwargs):
        def check_executed_tasks(target, expected):
            taskorder_file = glob.glob(f'{self.build_dir}/tmp/work/*/{target}/*/temp/log.task_order')
            try:
                with open(taskorder_file[0], 'r') as f:
                    tasks = [l.split()[1] for l in f.readlines()]
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

        # Check signature files for cachability issues like absolute paths in signatures
        result = process.run(f'{isar_root}/scripts/isar-sstate lint {self.build_dir}/sstate-cache '
                             f'--build-dir {self.build_dir} --sources-dir {isar_root}')
        if result.exit_status > 0:
            self.fail("Detected cachability issues")

        # Save contents of image deploy dir
        expected_files = set(glob.glob(f'{self.build_dir}/tmp/deploy/images/*/*'))

        # Rebuild image
        self.move_in_build_dir('tmp', 'tmp_before_sstate')
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
        self.move_in_build_dir('tmp', 'tmp_middle_sstate')
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
        self.move_in_build_dir('tmp', 'tmp_middle2_sstate')
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

    def perform_source_test(self, targets, **kwargs):
        def get_source_content(targets):
            sfiles = dict()
            for target in targets:
                sfiles[target] = dict()
                package = target.rsplit(':', 1)[-1]
                isar_apt = self.getVars('REPO_ISAR_DB_DIR', target=target)
                fpath = f'{package}/{package}*.tar.gz'
                targz = set(glob.glob(f'{isar_apt}/../apt/*/pool/*/*/{fpath}'))
                if len(targz) < 1:
                    self.fail('No source packages found')
                for filename in targz:
                    sfiles[target][filename] = self.get_tar_content(filename)
            return sfiles

        self.configure(**kwargs)

        tmp_layer_dir = self.create_tmp_layer()
        try:
            self.bitbake(targets, bitbake_cmd='do_deploy_source', **kwargs)

            sfiles_before = get_source_content(targets)
            for tdir in sfiles_before:
                for filename in sfiles_before[tdir]:
                    for file in sfiles_before[tdir][filename]:
                        if os.path.basename(file).startswith('.git'):
                            self.fail('Found .git files')

            package = targets[0].rsplit(':', 1)[-1]
            tmp_layer_nested_dirs = os.path.join(tmp_layer_dir,
                                                 'recipes-app', package)
            os.makedirs(tmp_layer_nested_dirs, exist_ok=True)
            bbappend_file = os.path.join(tmp_layer_nested_dirs,
                                         package + '.bbappend')
            with open(bbappend_file, 'w') as file:
                file.write('DPKG_SOURCE_EXTRA_ARGS = ""')

            self.bitbake(targets, bitbake_cmd='do_deploy_source', **kwargs)

            sfiles_after = get_source_content(targets)

            for tdir in sfiles_after:
                for filename in sfiles_after[tdir]:
                    if not sfiles_before[tdir][filename]:
                        self.fail('Source filenames are different')
                    diff = []
                    for file in sfiles_after[tdir][filename]:
                        if file not in sfiles_before[tdir][filename]:
                            diff.append(file)
                    if len(diff) < 1:
                        self.fail('Source packages are equal')
        finally:
            self.cleanup_tmp_layer(tmp_layer_dir)
