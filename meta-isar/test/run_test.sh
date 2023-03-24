#!/usr/bin/env bash

# Make Isar testsuite accessable
export PYTHONPATH=${PYTHONPATH}:${TESTSUITEDIR}

# install avocado in virtualenv in case it is not there already
if ! command -v avocado > /dev/null; then
    sudo apt-get -y update
    sudo apt-get -y install virtualenv
    rm -rf /tmp/avocado_venv
    virtualenv --python python3 /tmp/avocado_venv
    source /tmp/avocado_venv/bin/activate
    pip install avocado-framework==100.1
fi

# Install qemu
if ! command -v qemu-system-aarch64 > /dev/null; then
  sudo apt-get -y update
  sudo apt-get -y install --no-install-recommends qemu-system-aarch64 ipxe-qemu
fi

# Start tests in this dir
BASE_DIR="/build/avocado"

# Provide working path
mkdir -p .config/avocado
cat <<EOF > .config/avocado/avocado.conf
[datadir.paths]
base_dir = ${BASE_DIR}/
data_dir = ${BASE_DIR}/data
logs_dir = ${BASE_DIR}/logs
test_dir = ${BASE_DIR}/test
EOF
export VIRTUAL_ENV="./"

tsd=$(dirname $(realpath $0))/scripts

# Run SSH tests
avocado run --max-parallel-tasks=1 /work/sample_test.py -p test_script_dir=${tsd}
