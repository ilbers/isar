# Example module
#
# This software is a part of ISAR.
# Copyright (c) Siemens AG, 2018
#
# SPDX-License-Identifier: GPL-2.0

obj-m := example-module.o

INSTALL_MOD_PATH ?= $(DESTDIR)
export INSTALL_MOD_PATH

modules modules_install clean:
	$(MAKE) -C $(KDIR) M=$(PWD) $@

install: modules_install

.PHONY: modules modules_install install clean
