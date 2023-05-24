#!/usr/bin/env python3

from cibase import CIBaseTest

class SampleHwTest(CIBaseTest):
    def test_sample_script(self):
        self.init("/build")

        host = self.params.get('host', default='raspberry')
        port = self.params.get('port', default='22')

        self.ssh_start(user='ci', host=host, port=port,
                       script='sample_script.sh')
