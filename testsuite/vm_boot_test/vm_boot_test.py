#!/usr/bin/env python3

import os
import subprocess32
import sys
import time

from os.path import dirname
sys.path.append(dirname(__file__) + '/..')

import start_vm

from avocado import Test

class VmBootTest(Test):

    def test(self):
        """
        Run qemu

        Args:
            self: (todo): write your description
        """
        # TODO: add default values
        build_dir = self.params.get('build_dir', default='.')
        arch = self.params.get('arch', default='arm')
        distro = self.params.get('distro', default='stretch')
        time_to_wait = self.params.get('time_to_wait', default=60)

        self.log.info('===================================================')
        self.log.info('Running Isar VM boot test for (' + distro + '-' + arch + ')')
        self.log.info('Isar build folder is: ' + build_dir)
        self.log.info('===================================================')

        output_file = '/tmp/vm_boot_test.log'
        if os.path.exists(output_file):
            os.remove(output_file)

        cmdline = start_vm.format_qemu_cmdline(arch, build_dir, distro)
        cmdline.insert(1, '-nographic')
        cmdline.append('-serial')
        cmdline.append('file:' + output_file)

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
