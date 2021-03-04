#!/usr/bin/env python3

import os
import subprocess32
import sys
import time
import tempfile

from os.path import dirname
sys.path.append(dirname(__file__) + '/..')

import start_vm

from avocado import Test

class VmBase(Test):

    def vm_start(self, arch='amd64', distro='buster'):
        build_dir = self.params.get('build_dir', default='.')
        time_to_wait = self.params.get('time_to_wait', default=60)

        self.log.info('===================================================')
        self.log.info('Running Isar VM boot test for (' + distro + '-' + arch + ')')
        self.log.info('Isar build folder is: ' + build_dir)
        self.log.info('===================================================')

        fd, output_file = tempfile.mkstemp(suffix='_log.txt',
                                           prefix='vm_start_' + distro + '_' +
                                           arch + '_', dir=build_dir, text=True)

        cmdline = start_vm.format_qemu_cmdline(arch, build_dir, distro,
                                               output_file, None)
        cmdline.insert(1, '-nographic')

        self.log.info('QEMU boot line: ' + str(cmdline))

        devnull = open(os.devnull, 'w')

        p1 = subprocess32.Popen(cmdline, stdout=devnull, stderr=devnull)
        time.sleep(int(time_to_wait))
        p1.kill()
        p1.wait()

        if os.path.exists(output_file):
            if 'isar login:' in open(output_file).read():
                return

        self.fail('Test failed')

class VmBootTestFast(VmBase):

    """
    Test QEMU image start (fast)

    :avocado: tags=fast,full
    """
    def test_arm_stretch(self):
        self.vm_start('arm','stretch')

    def test_arm_buster(self):
        self.vm_start('arm','buster')

    def test_arm64_stretch(self):
        self.vm_start('arm64','stretch')

    def test_amd64_stretch(self):
        self.vm_start('amd64','stretch')

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
