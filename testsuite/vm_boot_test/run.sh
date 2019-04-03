#!/bin/bash

avocado run vm_boot_test.py --mux-yaml test:variant.yaml --mux-inject build_dir:$BUILDDIR time_to_wait:300
