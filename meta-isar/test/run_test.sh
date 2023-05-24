#!/usr/bin/env bash

set -e

test_dir=$(dirname $(realpath $0))

. ${test_dir}/common.sh

# Install qemu
if ! command -v qemu-system-aarch64 > /dev/null; then
  sudo apt-get -y update
  sudo apt-get -y install --no-install-recommends qemu-system-aarch64 ipxe-qemu
fi

# Run SSH tests
avocado run --max-parallel-tasks=1 /work/sample_test.py -p test_script_dir=${test_dir}
