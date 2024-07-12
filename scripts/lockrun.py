#!/usr/bin/env python3
#
# Helper script to use bitbake locks in shell
# Copyright (c) 2024, ilbers GmbH

import argparse
import os
import subprocess
import sys

sys.path.append(os.path.join(os.path.dirname(__file__), '../bitbake/lib'))

from bb import utils


def parse_args():
    parser = argparse.ArgumentParser()
    parser.add_argument('-f', '--file', help='Lock file name.', required=True)
    parser.add_argument(
        '-r', '--read', action="store_true", help='Use read (shared) locking.'
    )
    group = parser.add_mutually_exclusive_group(required=True)
    group.add_argument('-c', '--command', help='Command(s) to execute.')
    group.add_argument(
        '-s',
        '--shell',
        action="store_true",
        help='Execute commands from stdin.',
    )
    return parser.parse_args()


if __name__ == "__main__":
    args = parse_args()

    with utils.fileslocked([args.file], shared=args.read):
        if args.shell:
            cmd = sys.stdin.read()
        else:
            cmd = args.command
        try:
            subprocess.run(cmd, check=True, shell=True)
        except subprocess.CalledProcessError as e:
            exit(e.returncode)
