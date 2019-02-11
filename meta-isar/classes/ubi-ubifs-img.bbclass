# UBI with UBIFS image recipe
#
# This software is a part of ISAR.
# Copyright (C) Siemens AG, 2019
#
# SPDX-License-Identifier: MIT

inherit ubi-img ubifs-img fit-img
addtask do_ubi_image after do_ubifs_image
addtask do_ubi_image after do_fit_image
