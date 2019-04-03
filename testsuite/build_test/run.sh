#!/bin/bash

avocado run build_test.py --mux-yaml test:variant.yaml --mux-inject build_dir:$BUILDDIR
