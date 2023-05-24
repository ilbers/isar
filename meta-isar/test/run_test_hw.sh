#!/usr/bin/env bash

set -e

test_dir=$(dirname $(realpath $0))

. ${test_dir}/common.sh

# Run SSH tests
avocado run --max-parallel-tasks=1 /work/sample_test_hw.py -p test_script_dir=${test_dir} -p host=rpi $@
