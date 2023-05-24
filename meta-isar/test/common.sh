#!/usr/bin/env bash

set -e

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
