#!/usr/bin/env python3

from cibase import CIBaseTest

class SampleTest(CIBaseTest):
    def test_sample_script(self):
        self.init("/build")
        self.vm_start('arm64','bullseye', image='isar-image-ci', \
                    script='sample_script.sh')
