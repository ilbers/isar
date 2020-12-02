#!/usr/bin/env python3

import logging
import os
import re
import select
import shutil
import subprocess

from avocado import Test
from avocado.utils import path
from avocado.utils import process

isar_root = os.path.dirname(__file__) + '/../..'
backup_prefix = '.ci-backup'

app_log = logging.getLogger("avocado.app")

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

    def init(self, build_dir):
        os.chdir(isar_root)
        path.usable_rw_dir(build_dir)
        output = process.getoutput('/bin/bash -c "source isar-init-build-env \
                                    %s 2>&1 >/dev/null; env"' % build_dir)
        env = dict(((x.split('=', 1) + [''])[:2] \
                    for x in output.splitlines() if x != ''))
        os.environ.update(env)

    def confprepare(self, build_dir, compat_arch, cross, debsrc_cache):
        with open(build_dir + '/conf/ci_build.conf', 'w') as f:
            if compat_arch:
                f.write('ISAR_ENABLE_COMPAT_ARCH_amd64 = "1"\n')
                f.write('ISAR_ENABLE_COMPAT_ARCH_arm64 = "1"\n')
                f.write('ISAR_ENABLE_COMPAT_ARCH_debian-stretch_amd64 = "0"\n')
                f.write('IMAGE_INSTALL += "kselftest"\n')
            if cross:
                f.write('ISAR_CROSS_COMPILE = "1"\n')
            if debsrc_cache:
                f.write('BASE_REPO_FEATURES = "cache-deb-src"\n')
            distro_apt_premir = os.getenv('DISTRO_APT_PREMIRRORS')
            if distro_apt_premir:
                f.write('DISTRO_APT_PREMIRRORS = "%s"\n' % distro_apt_premir)

        with open(build_dir + '/conf/local.conf', 'r+') as f:
            for line in f:
                if 'include ci_build.conf' in line:
                    break
            else:
                f.write('\ninclude ci_build.conf')

    def containerprep(self, build_dir):
        with open(build_dir + '/conf/ci_build.conf', 'a') as f:
            f.write('SDK_FORMATS = "docker-archive"\n')
            f.write('IMAGE_INSTALL_remove = "example-module-${KERNEL_NAME} enable-fsck"\n')

    def confcleanup(self, build_dir):
        open(build_dir + '/conf/ci_build.conf', 'w').close()

    def deletetmp(self, build_dir):
        process.run('rm -rf ' + build_dir + '/tmp', sudo=True)

    def bitbake(self, build_dir, target, cmd, args):
        os.chdir(build_dir)
        cmdline = ['bitbake']
        if args:
            cmdline.append(args)
        if cmd:
            cmdline.append('-c')
            cmdline.append(cmd)
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
                    if fd == p1.stdout.fileno():
                        self.log.info(p1.stdout.readline().rstrip())
                    if fd == p1.stderr.fileno():
                        app_log.error(p1.stderr.readline().rstrip())
            p1.wait()
            if p1.returncode:
                self.fail('Bitbake failed')

    def backupfile(self, path):
        try:
            shutil.copy2(path, path + backup_prefix)
        except FileNotFoundError:
            self.log.warn(path + ' not exist')

    def backupmove(self, path):
        try:
            shutil.move(path, path + backup_prefix)
        except FileNotFoundError:
            self.log.warn(path + ' not exist')

    def restorefile(self, path):
        try:
            shutil.move(path + backup_prefix, path)
        except FileNotFoundError:
            self.log.warn(path + backup_prefix + ' not exist')

    def getlayerdir(self, layer):
        try:
            path.find_command('bitbake')
        except path.CmdNotFoundError:
            build_dir = self.params.get('build_dir',
                                        default=isar_root + '/build')
            self.init(build_dir)
        output = process.getoutput('bitbake -e | grep "^LAYERDIR_.*="')
        env = dict(((x.split('=', 1) + [''])[:2] \
                    for x in output.splitlines() if x != ''))

        return env['LAYERDIR_' + layer].strip('"')
