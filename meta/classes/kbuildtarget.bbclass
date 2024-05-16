# This software is a part of ISAR.
# Copyright (C) 2024 Siemens AG
#
# SPDX-License-Identifier: MIT

python kbuildtarget_virtclass_handler() {
    pn = e.data.getVar('PN')
    if pn.endswith('-kbuildtarget'):
        e.data.setVar('BPN', pn[:-len('-kbuildtarget')])
        e.data.appendVar('OVERRIDES', ':class-kbuildtarget')
}
addhandler kbuildtarget_virtclass_handler
kbuildtarget_virtclass_handler[eventmask] = "bb.event.RecipePreFinalise"
