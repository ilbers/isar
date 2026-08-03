# This software is a part of Isar.
# Copyright (C) 2026 Siemens AG
#
# SPDX-License-Identifier: MIT

python libctarget_virtclass_handler() {
    pn = e.data.getVar('PN')
    if pn.endswith('-libctarget'):
        e.data.setVar('BPN', pn[:-len('-libctarget')])
        e.data.appendVar('OVERRIDES', ':class-libctarget')
}
addhandler libctarget_virtclass_handler
libctarget_virtclass_handler[eventmask] = "bb.event.RecipePreFinalise"
