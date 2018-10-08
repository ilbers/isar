# This software is a part of ISAR.
# Copyright (C) 2018 Siemens AG
#
# SPDX-License-Identifier: MIT

def get_wks_full_path(d):
    if (d.getVar('IMAGE_TYPE', True) or '') != 'wic-img':
        return ""

    wks_full_path = None

    wks_file = d.getVar('WKS_FILE', True)
    if not wks_file.endswith('.wks'):
        wks_file += '.wks'

    if os.path.isabs(wks_file):
        if os.path.exists(wks_file):
            wks_full_path = wks_file
    else:
        bbpaths = d.getVar('BBPATH', True).split(':')
        corebase = d.getVar('COREBASE', True)
        search_path = ':'.join('%s/wic' % p for p in bbpaths) + ':' + \
            ':'.join('%s/scripts/lib/wic/canned-wks' % l \
                     for l in (bbpaths + [corebase]))
        wks_full_path = bb.utils.which(search_path, wks_file)

    if not wks_full_path:
        bb.fatal("WKS_FILE '%s' not found" % wks_file)

    return wks_full_path
