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
    source /tmp/avocado_venv/bin/activate
    pip install avocado-framework
fi

# Get Avocado build tests path
TESTSUITE_DIR="$(pwd)/testsuite"

# Start tests in current path by default
BASE_DIR=./build

# Check dependencies
DEPENDENCIES="umoci skopeo"
for prog in ${DEPENDENCIES} ; do
    if [ ! -x "$(which $prog)" ] ; then
        echo "missing $prog in PATH" >&2
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
    echo "    -c, --cross              enable cross-compilation."
    echo "    -d, --debug              enable debug bitbake output."
    echo "    -f, --fast               cross build reduced set of configurations."
    echo "    -q, --quiet              suppress verbose bitbake output."
    echo "    -r, --repro              enable use of cached base repository."
    echo "    --help                   display this message and exit."
    echo
    echo "Exit status:"
    echo " 0  if OK,"
    echo " 3  if invalid parameters are passed."
}

TAGS="full"
CROSS_BUILD="0"
QUIET="0"

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
    -c|--cross)
        CROSS_BUILD="1"
        ;;
    -d|--debug)
        VERBOSE="--show=app,test"
        ;;
    -f|--fast)
        # Start build for the reduced set of configurations
        # Enforce cross-compilation to speed up the build
        TAGS="fast"
        CROSS_BUILD="1"
        ;;
    -q|--quiet)
        QUIET="1"
        ;;
    -r|--repro)
        REPRO_BUILD="1"
        # This switch is deprecated, just here to not cause failing CI on
        # legacy configs
        case "$2" in
        -s|--sign) shift ;;
        esac
        ;;
    *)
        echo "error: invalid parameter '$key', please try '--help' to get list of supported parameters"
        exit $ES_BUG
        ;;
    esac

    shift
done

if [ -z "$REPRO_BUILD" ]; then
    TAGS="$TAGS,-repro"
fi

# Provide working path
mkdir -p .config/avocado
cat <<EOF > .config/avocado/avocado.conf
[datadir.paths]
base_dir = $(realpath $BASE_DIR)/
test_dir = $(realpath $BASE_DIR)/tests
data_dir = $(realpath $BASE_DIR)/data
logs_dir = $(realpath $BASE_DIR)/job-results
EOF
export VIRTUAL_ENV="./"

# the real stuff starts here, trace commands from now on
set -x

avocado $VERBOSE run "$TESTSUITE_DIR/build_test.py" \
    -t $TAGS --test-runner=runner --disable-sysinfo \
    -p quiet=$QUIET -p cross=$CROSS_BUILD
