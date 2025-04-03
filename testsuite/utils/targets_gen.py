#!/usr/bin/env python3

"""
# This software is a part of Isar.
# Copyright (C) 2024 ilbers GmbH

# targets_gen.py: Generates yaml for yaml-to-mux Avocado varianter plugin.
"""

import os
import sys

sys.path.insert(0, os.path.dirname(os.path.realpath(__file__)) + '/..')
from cibuilder import CIBuilder

class TGen(CIBuilder):
    def __init__(self):
        super(CIBuilder, self).__init__()
        self.gen_targets_yaml()
    def test():
        pass

def main():
    TGen()

if __name__ == "__main__":
    main()
