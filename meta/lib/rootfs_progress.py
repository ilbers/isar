# This software is a part of ISAR.
# Copyright (c) Siemens AG, 2024
#
# SPDX-License-Identifier: MIT

import bb.progress
import re


class PkgsProgressHandler(bb.progress.ProgressHandler):
    def __init__(self, d, outfile):
        self._outfile = outfile
        self._progress = d.rootfs_progress
        self._progress.update(0)
        self._linebuffer = ''
        self._num_pkgs = 0
        self._pkg = 0
        self._stage = 'prepare'

    def write(self, string):
        self._outfile.write(string)
        self._linebuffer += string
        while True:
            breakpos = self._linebuffer.find('\n') + 1
            if breakpos == 0:
                break
            line = self._linebuffer[:breakpos]
            self._linebuffer = self._linebuffer[breakpos:]

            if self._stage == 'prepare':
                self.process_total(line)
            else:
                self.process_line(line)

    def process_total(self, line):
        m = re.search(r'^([0-9]+) upgraded, ([0-9]+) newly installed', line)
        if m:
            self._num_pkgs = int(m.group(1)) + int(m.group(2))
            self._stage = 'post-prepare'

    def process_line(self, line):
        return


class PkgsDownloadProgressHandler(PkgsProgressHandler):
    def __init__(self, d, outfile, otherargs=None):
        super().__init__(d, outfile)

    def process_line(self, line):
        if line.startswith('Get:'):
            self._pkg += 1
            self._progress.update(99 * self._pkg / self._num_pkgs)


class PkgsInstallProgressHandler(PkgsProgressHandler):
    def __init__(self, d, outfile, otherargs=None):
        self._pkg_set_up = 0
        super().__init__(d, outfile)

    def process_line(self, line):
        if line.startswith('Preparing to unpack'):
            self._pkg += 1
        elif line.startswith('Setting up'):
            self._pkg_set_up += 1
        else:
            return

        progress = 99 * (self._pkg + self._pkg_set_up) / (self._num_pkgs * 2)
        self._progress.update(progress)


class InitrdProgressHandler(PkgsProgressHandler):
    def __init__(self, d, outfile, otherargs=None):
        super().__init__(d, outfile)

    def process_total(self, line):
        m = re.search(r'^Total number of modules: ([0-9]+)', line)
        if m:
            # in MODULES=most mode, we install ~half of all modules
            self._num_pkgs = int(m.group(1)) // 2
            self._stage = 'post-prepare'

    def process_line(self, line):
        if (
            line.startswith("Adding module")
            or line.startswith("dracut-install: cp")
            or line.startswith("dracut-install: Failed to find module")
        ):
            self._pkg += 1
        elif line.startswith('(excluding'):
            self._pkg += len(line.split(' ')) - 1
        else:
            return
        self._progress.update(99 * self._pkg / self._num_pkgs)
