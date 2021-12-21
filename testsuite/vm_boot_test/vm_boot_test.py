#!/usr/bin/env python3

import os
import select
import subprocess
import sys
import time
import tempfile

from os.path import dirname
sys.path.append(dirname(__file__) + '/..')

import start_vm

from avocado import Test
from avocado.utils import process
from avocado.utils import path

class CanBeFinished(Exception):
    pass

class VmBase(Test):

    def check_bitbake(self, build_dir):
        try:
            path.find_command('bitbake')
        except path.CmdNotFoundError:
            out = process.getoutput('/bin/bash -c "cd ../.. && \
                                    source isar-init-build-env \
                                    %s 2>&1 >/dev/null; env"' % build_dir)
            env = dict(((x.split('=', 1) + [''])[:2] \
                        for x in output.splitlines() if x != ''))
            os.environ.update(env)

    def vm_start(self, arch='amd64', distro='buster'):
        build_dir = self.params.get('build_dir', default='.')
        time_to_wait = self.params.get('time_to_wait', default=60)

        self.log.info('===================================================')
        self.log.info('Running Isar VM boot test for (' + distro + '-' + arch + ')')
        self.log.info('Isar build folder is: ' + build_dir)
        self.log.info('===================================================')

        self.check_bitbake(build_dir)

        fd, output_file = tempfile.mkstemp(suffix='_log.txt',
                                           prefix='vm_start_' + distro + '_' +
                                           arch + '_', dir=build_dir, text=True)
        os.chmod(output_file, 0o644)

        cmdline = start_vm.format_qemu_cmdline(arch, build_dir, distro,
                                               output_file, None)
        cmdline.insert(1, '-nographic')

        self.log.info('QEMU boot line: ' + str(cmdline))

        login_prompt = b'isar login:'
        service_prompt = b'Just an example'

        timeout = time.time() + int(time_to_wait)

        p1 = subprocess.Popen(cmdline, stdout=subprocess.PIPE,
                              stderr=subprocess.PIPE)
        try:
            poller = select.poll()
            poller.register(p1.stdout, select.POLLIN)
            poller.register(p1.stderr, select.POLLIN)
            while time.time() < timeout and p1.poll() is None:
                events = poller.poll(1000 * (timeout - time.time()))
                for fd, event in events:
                    if fd == p1.stdout.fileno():
                        # Wait for the complete string if it is read in chunks
                        # like "i", "sar", " login:"
                        time.sleep(0.01)
                        data = os.read(fd, 1024)
                        if login_prompt in data:
                            raise CanBeFinished
                    if fd == p1.stderr.fileno():
                        self.log.error(p1.stderr.readline())
        except CanBeFinished:
            self.log.debug('Got login prompt')
        finally:
            if p1.poll() is None:
                p1.kill()
            p1.wait()

        if os.path.exists(output_file):
            with open(output_file, "rb") as f1:
                data = f1.read()
                if service_prompt in data and login_prompt in data:
                    return
                else:
                    self.log.error(data)

        self.fail('Log ' + output_file)

class VmBootTestFast(VmBase):

    """
    Test QEMU image start (fast)

    :avocado: tags=fast,full
    """
    def test_arm_bullseye(self):
        self.vm_start('arm','bullseye')

    def test_arm_buster(self):
        self.vm_start('arm','buster')

    def test_arm64_bullseye(self):
        self.vm_start('arm64','bullseye')

    def test_amd64_bullseye(self):
        self.vm_start('amd64','bullseye')

class VmBootTestFull(VmBase):

    """
    Test QEMU image start (full)

    :avocado: tags=full
    """
    def test_i386_stretch(self):
        self.vm_start('i386','stretch')

    def test_i386_buster(self):
        self.vm_start('i386','buster')

    def test_amd64_buster(self):
        self.vm_start('amd64','buster')

    def test_amd64_focal(self):
        self.vm_start('amd64','focal')
