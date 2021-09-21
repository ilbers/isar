# This software is a part of ISAR.
# Copyright (c) Siemens AG, 2021
#
# SPDX-License-Identifier: MIT

inherit dpkg-prebuilt

# NOTE: The deb packages should almost never be stored in the repo itself but
#       rather fetched from a binary-serving location. For this example, local
#       storage was just simpler to maintain across all archs and distros.
SRC_URI = "file://example-prebuilt_1.0.0-0_all.deb"

# Only needed if recipe name != package name, as in this case. Or multiple
# packages are provided by a single recipe.
PROVIDES += "example-prebuilt"
