#!/usr/bin/env python3

import os
import subprocess32
import sys
from os.path import dirname

from avocado import Test

class BuildTest(Test):

    def test(self):
        """
        Run the test.

        Args:
            self: (todo): write your description
        """
        # TODO: add default values
        build_dir = self.params.get('build_dir', default='.')
        arch = self.params.get('arch', default='arm')
        distro = self.params.get('distro', default='stretch')

        self.log.info('===================================================')
        self.log.info('Running Isar build test for (' + distro + '-' + arch + ')')
        self.log.info('Isar build folder is: ' + build_dir)
        self.log.info('===================================================')

        #isar_root = dirname(__file__) + '/..'
        os.chdir(build_dir)
        cmdline = ['bitbake', 'mc:qemu' + arch + '-' + distro + ':isar-image-base']
        p1 = subprocess32.run(cmdline)

        if p1.returncode:
            self.fail('Test failed')
