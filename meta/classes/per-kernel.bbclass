# Generate per-kernel recipe variants
#
# Recipes which are specific to a specific kernel currently append KERNEL_NAME to the PN,
# and depend on and target that specific kernel. For a machine which supports and builds
# multiple kernel images, there is a need to generate a variant of the recipe for each
# kernel image.
#
# Each variant listed in KERNEL_NAMES will add `kernel-<kernel_name>` to the OVERRIDES variable, and
# `per-kernel:<kernel_name>` to the BBCLASSEXTEND variable. In addition, KERNEL_NAME will be
# set to the kernel name for the current variant.
#
# Copyright (c) Siemens AG, 2025
# SPDX-License-Identifier: MIT

OVERRIDES .= ":kernel-${KERNEL_NAME}"

KERNEL_NAMES ?= "${KERNEL_NAME}"
BBCLASSEXTEND += "${@' '.join(f'per-kernel:{kernel}' for kernel in d.getVar('KERNEL_NAMES').split() if kernel != d.getVar('KERNEL_NAME'))}"

python per_kernel_virtclass_handler() {
    orig_pn = d.getVar('PN')

    d = e.data
    extend = d.getVar('BBEXTENDCURR') or ''
    variant = d.getVar('BBEXTENDVARIANT') or ''
    if extend != 'per-kernel':
        return
    elif variant == '':
        d.appendVar('PROVIDES', f' {orig_pn}')
        return

    d.setVar('KERNEL_NAME', variant)
}
addhandler per_kernel_virtclass_handler
per_kernel_virtclass_handler[eventmask] = "bb.event.RecipePreFinalise"
