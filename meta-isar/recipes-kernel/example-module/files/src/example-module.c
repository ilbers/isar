/*
 * Example modules
 *
 * Copyright (c) Siemens AG, 2018
 *
 * SPDX-License-Identifier: GPL-2.0
 */

#include <linux/module.h>

static int __init example_module_init(void)
{
	printk("Just an example\n");
	return -ENOANO;
}

module_init(example_module_init);

MODULE_LICENSE("GPL");
