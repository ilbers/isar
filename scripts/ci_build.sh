#!/usr/bin/env bash
# Script for CI system build
#
# Alexander Smirnov <asmirnov@ilbers.de>
# Copyright (c) 2016-2018 ilbers GmbH

set -e

ES_BUG=3

# Export $PATH to use 'parted' tool
export PATH=$PATH:/sbin

# Go to Isar root
cd "$(dirname "$0")/.."

# install avocado in virtualenv in case it is not there already
if ! command -v avocado > /dev/null; then
    sudo apt-get update -qq
    sudo apt-get install -y virtualenv
    rm -rf /tmp/avocado_venv
    virtualenv --python python3 /tmp/avocado_venv
    # shellcheck source=/dev/null
    source /tmp/avocado_venv/bin/activate
    pip install avocado-framework==100.1
fi

# Get Avocado build tests path
TESTSUITE_DIR="$(pwd)/testsuite"

# Start tests in current path by default
BASE_DIR=./build

# Check dependencies
DEPENDENCIES="umoci skopeo"
for prog in ${DEPENDENCIES} ; do
    if ! command -v "${prog}" > /dev/null; then
        echo "missing ${prog} in PATH" >&2
    fi
done

show_help() {
    echo "This script builds the default Isar images."
    echo
    echo "Usage:"
    echo "    $0 [params]"
    echo
    echo "Parameters:"
    echo "    -b, --base BASE_DIR      set path to base directory. If not set,"
    echo "                             the tests will be started in current path."
    echo "    -d, --debug              enable debug bitbake output."
    echo "    -T, --tags               specify basic avocado tags."
    echo "    --help                   display this message and exit."
    echo
    echo "Exit status:"
    echo " 0  if OK,"
    echo " 3  if invalid parameters are passed."
}

# Parse command line to get user configuration
while [ $# -gt 0 ]
do
    key="$1"

    case $key in
    -h|--help)
        show_help
        exit 0
        ;;
    -b|--base)
        BASE_DIR="$2"
        shift
        ;;
    -d|--debug)
        VERBOSE="--show=app,test"
        ;;
    -T|--tags)
        TAGS="$2"
        shift
        ;;
    -S|--sstate)
        SSTATE="-p sstate=$2"
        shift
        ;;
    -f|--fast)
        # Start build for the reduced set of configurations
        FAST="1"
        echo "warning: deprecated parameter '$key', consider using '-T fast' instead"
        ;;
    -q|--quiet)
        echo "warning: deprecated parameter '$key', it is applied by default"
        ;;
    -n|--norun)
        NORUN="1"
        echo "warning: deprecated parameter '$key', consider using '-T <TAG>,-startvm' instead"
        ;;
    -t|--timeout)
        TIMEOUT="-p time_to_wait=$2"
        shift
        ;;
    -c|--cross|-r|--repro|-s|--sign)
        # Just not to cause CI failures on legacy configs
        echo "warning: deprecated parameter '$key'"
        ;;
    *)
        echo "error: invalid parameter '$key', please try '--help' to get list of supported parameters"
        exit $ES_BUG
        ;;
    esac

    shift
done

if [ -z "$TAGS" ]; then
    if [ -n "$FAST" ]; then
        TAGS="fast"
    else
        TAGS="full"
    fi
fi

# Deprecated
if [ -n "$NORUN" ]; then
    TAGS="$TAGS,-startvm"
fi

if echo "$TAGS" | grep -Fqive "-startvm"; then
    if [ ! -f /usr/share/doc/qemu-system/copyright ]; then
        sudo apt-get update -qq
        sudo apt-get install -y --no-install-recommends qemu-system ovmf
    fi
fi

# Provide working path
mkdir -p .config/avocado
cat <<EOF > .config/avocado/avocado.conf
[datadir.paths]
base_dir = $(realpath "${BASE_DIR}")/
test_dir = $(realpath "${BASE_DIR}")/tests
data_dir = $(realpath "${BASE_DIR}")/data
logs_dir = $(realpath "${BASE_DIR}")/job-results
EOF
export VIRTUAL_ENV="./"

# the real stuff starts here, trace commands from now on
set -x

avocado ${VERBOSE} run "${TESTSUITE_DIR}/citest.py" \
    -t "${TAGS}" --max-parallel-tasks=1 --disable-sysinfo \
    ${SSTATE} ${TIMEOUT}
