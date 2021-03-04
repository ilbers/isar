#!/bin/bash

avocado run vm_boot_test.py -t full -p build_dir="$BUILDDIR" -p time_to_wait=300
