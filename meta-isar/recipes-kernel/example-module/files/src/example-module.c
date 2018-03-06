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
	return 0;
}

static void __exit example_module_exit(void)
{
	return;
}

module_init(example_module_init);
module_exit(example_module_exit);

MODULE_LICENSE("GPL");
