#!/bin/sh

set -e

lsmod | grep "^${1} "
