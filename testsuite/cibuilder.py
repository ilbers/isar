#!/usr/bin/env python3

import logging
import os
import select
import shutil
import subprocess
import time
import tempfile

import start_vm

from avocado import Test
from avocado.utils import path
from avocado.utils import process

isar_root = os.path.abspath(os.path.join(os.path.dirname(__file__), '..'))
backup_prefix = '.ci-backup'

app_log = logging.getLogger("avocado.app")

class CanBeFinished(Exception):
    pass

class CIBuilder(Test):
    def setUp(self):
        super(CIBuilder, self).setUp()
        job_log = os.path.join(os.path.dirname(self.logdir), '..', 'job.log')
        self._file_handler = logging.FileHandler(filename=job_log)
        self._file_handler.setLevel(logging.ERROR)
        fmt = ('%(asctime)s %(module)-16.16s L%(lineno)-.4d %('
               'levelname)-5.5s| %(message)s')
        formatter = logging.Formatter(fmt=fmt)
        self._file_handler.setFormatter(formatter)
        app_log.addHandler(self._file_handler)

    def init(self, build_dir='build'):
        # initialize build_dir and setup environment
        # needs to run once (per test case)
        if hasattr(self, 'build_dir'):
            self.error("Broken test implementation: init() called multiple times.")
        self.build_dir = os.path.join(isar_root, build_dir)
        os.chdir(isar_root)
        path.usable_rw_dir(self.build_dir)
        output = process.getoutput('/bin/bash -c "source isar-init-build-env \
                                    %s 2>&1 >/dev/null; env"' % self.build_dir)
        env = dict(((x.split('=', 1) + [''])[:2] \
                    for x in output.splitlines() if x != ''))
        os.environ.update(env)

    def check_init(self):
        if not hasattr(self, 'build_dir'):
            self.error("Broken test implementation: need to call init().")

    def configure(self, compat_arch=True, cross=None, debsrc_cache=False,
                  container=False, ccache=False, sstate=False, offline=False,
                  gpg_pub_key=None, wic_deploy_parts=False, **kwargs):
        # write configuration file and set bitbake_args
        # can run multiple times per test case
        self.check_init()

        # get parameters from avocado cmdline
        quiet = bool(int(self.params.get('quiet', default=0)))
        if cross is None:
            cross = bool(int(self.params.get('cross', default=0)))

        # get parameters from environment
        distro_apt_premir = os.getenv('DISTRO_APT_PREMIRRORS')

        self.log.info(f'===================================================\n'
                      f'Configuring build_dir {self.build_dir}\n'
                      f'  compat_arch = {compat_arch}\n'
                      f'  cross = {cross}\n'
                      f'  debsrc_cache = {debsrc_cache}\n'
                      f'  offline = {offline}\n'
                      f'  container = {container}\n'
                      f'  ccache = {ccache}\n'
                      f'  sstate = {sstate}\n'
                      f'  gpg_pub_key = {gpg_pub_key}\n'
                      f'  wic_deploy_parts = {wic_deploy_parts}\n'
                      f'===================================================')

        # determine bitbake_args
        self.bitbake_args = []
        if not quiet:
            self.bitbake_args.append('-v')
        if not sstate:
            self.bitbake_args.append('--no-setscene')

        # write ci_build.conf
        with open(self.build_dir + '/conf/ci_build.conf', 'w') as f:
            if compat_arch:
                f.write('ISAR_ENABLE_COMPAT_ARCH_amd64 = "1"\n')
                f.write('ISAR_ENABLE_COMPAT_ARCH_arm64 = "1"\n')
                f.write('ISAR_ENABLE_COMPAT_ARCH_debian-stretch_amd64 = "0"\n')
                f.write('IMAGE_INSTALL += "kselftest"\n')
            if cross:
                f.write('ISAR_CROSS_COMPILE = "1"\n')
            if debsrc_cache:
                f.write('BASE_REPO_FEATURES = "cache-deb-src"\n')
            if offline:
                f.write('ISAR_USE_CACHED_BASE_REPO = "1"\n')
                f.write('BB_NO_NETWORK = "1"\n')
            if container:
                f.write('SDK_FORMATS = "docker-archive"\n')
                f.write('IMAGE_INSTALL_remove = "example-module-${KERNEL_NAME} enable-fsck"\n')
            if gpg_pub_key:
                f.write('BASE_REPO_KEY="file://' + gpg_pub_key + '"\n')
            if wic_deploy_parts:
                f.write('WIC_DEPLOY_PARTITIONS = "1"\n')
            if distro_apt_premir:
                f.write('DISTRO_APT_PREMIRRORS = "%s"\n' % distro_apt_premir)
            if ccache:
                f.write('USE_CCACHE = "1"\n')
                f.write('CCACHE_TOP_DIR = "${TOPDIR}/ccache"\n')

        # include ci_build.conf in local.conf
        with open(self.build_dir + '/conf/local.conf', 'r+') as f:
            for line in f:
                if 'include ci_build.conf' in line:
                    break
            else:
                f.write('\ninclude ci_build.conf')

    def unconfigure(self):
        self.check_init()
        open(self.build_dir + '/conf/ci_build.conf', 'w').close()

    def delete_from_build_dir(self, path):
        self.check_init()
        process.run('rm -rf ' + self.build_dir + '/' + path, sudo=True)

    def move_in_build_dir(self, src, dst):
        self.check_init()
        process.run('mv ' + self.build_dir + '/' + src + ' ' + self.build_dir + '/' + dst, sudo=True)

    def bitbake(self, target, bitbake_cmd=None, **kwargs):
        self.check_init()
        self.log.info('===================================================')
        self.log.info('Building ' + str(target))
        self.log.info('===================================================')
        os.chdir(self.build_dir)
        cmdline = ['bitbake']
        if self.bitbake_args:
            cmdline.extend(self.bitbake_args)
        if bitbake_cmd:
            cmdline.append('-c')
            cmdline.append(bitbake_cmd)
        if isinstance(target, list):
            cmdline.extend(target)
        else:
            cmdline.append(target)

        with subprocess.Popen(" ".join(cmdline), stdout=subprocess.PIPE,
                              stderr=subprocess.PIPE, universal_newlines=True,
                              shell=True) as p1:
            poller = select.poll()
            poller.register(p1.stdout, select.POLLIN)
            poller.register(p1.stderr, select.POLLIN)
            while p1.poll() is None:
                events = poller.poll(1000)
                for fd, event in events:
                    if event != select.POLLIN:
                        continue
                    if fd == p1.stdout.fileno():
                        self.log.info(p1.stdout.readline().rstrip())
                    if fd == p1.stderr.fileno():
                        app_log.error(p1.stderr.readline().rstrip())
            p1.wait()
            if p1.returncode:
                self.fail('Bitbake failed')

    def backupfile(self, path):
        self.check_init()
        try:
            shutil.copy2(path, path + backup_prefix)
        except FileNotFoundError:
            self.log.warn(path + ' not exist')

    def backupmove(self, path):
        self.check_init()
        try:
            shutil.move(path, path + backup_prefix)
        except FileNotFoundError:
            self.log.warn(path + ' not exist')

    def restorefile(self, path):
        self.check_init()
        try:
            shutil.move(path + backup_prefix, path)
        except FileNotFoundError:
            self.log.warn(path + backup_prefix + ' not exist')

    def getlayerdir(self, layer):
        self.check_init()
        output = process.getoutput('bitbake -e | grep "^LAYERDIR_.*="')
        env = dict(((x.split('=', 1) + [''])[:2] \
                    for x in output.splitlines() if x != ''))

        return env['LAYERDIR_' + layer].strip('"')

    def vm_start(self, arch='amd64', distro='buster', enforce_pcbios=False):
        time_to_wait = self.params.get('time_to_wait', default=60)

        self.log.info('===================================================')
        self.log.info('Running Isar VM boot test for (' + distro + '-' + arch + ')')
        self.log.info('Isar build folder is: ' + self.build_dir)
        self.log.info('===================================================')

        self.check_init()

        logdir = '%s/vm_start' % self.build_dir
        if not os.path.exists(logdir):
            os.mkdir(logdir)
        prefix = '%s-vm_start_%s_%s_' % (time.strftime('%Y%m%d-%H%M%S'),
                                         distro, arch)
        fd, output_file = tempfile.mkstemp(suffix='_log.txt', prefix=prefix,
                                           dir=logdir, text=True)
        os.chmod(output_file, 0o644)
        latest_link = '%s/vm_start_%s_%s_latest.txt' % (logdir, distro, arch)
        if os.path.exists(latest_link):
            os.unlink(latest_link)
        os.symlink(os.path.basename(output_file), latest_link)

        cmdline = start_vm.format_qemu_cmdline(arch, self.build_dir, distro,
                                               output_file, None, enforce_pcbios)
        cmdline.insert(1, '-nographic')

        self.log.info('QEMU boot line: ' + str(cmdline))

        login_prompt = b'isar login:'
        service_prompt = b'Just an example'

        timeout = time.time() + int(time_to_wait)

        p1 = subprocess.Popen(cmdline, stdout=subprocess.PIPE,
                              stderr=subprocess.PIPE, universal_newlines=True)
        try:
            poller = select.poll()
            poller.register(p1.stdout, select.POLLIN)
            poller.register(p1.stderr, select.POLLIN)
            while time.time() < timeout and p1.poll() is None:
                events = poller.poll(1000 * (timeout - time.time()))
                for fd, event in events:
                    if event != select.POLLIN:
                        continue
                    if fd == p1.stdout.fileno():
                        # Wait for the complete string if it is read in chunks
                        # like "i", "sar", " login:"
                        time.sleep(0.01)
                        data = os.read(fd, 1024)
                        if login_prompt in data:
                            raise CanBeFinished
                    if fd == p1.stderr.fileno():
                        app_log.error(p1.stderr.readline().rstrip())
        except CanBeFinished:
            self.log.debug('Got login prompt')
        finally:
            if p1.poll() is None:
                p1.kill()
            p1.wait()

        if os.path.exists(output_file) and os.path.getsize(output_file) > 0:
            with open(output_file, "rb") as f1:
                data = f1.read()
                if service_prompt in data and login_prompt in data:
                    return
                else:
                    app_log.error(data.decode(errors='replace'))

        self.fail('Log ' + output_file)
