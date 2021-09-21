# This software is a part of ISAR.
# Copyright (C) 2021 Siemens AG
#
# SPDX-License-Identifier: MIT

inherit dpkg-base

python do_unpack_prepend() {
    # enforce unpack=false
    src_uri = (d.getVar('SRC_URI', True) or '').split()
    if len(src_uri) == 0:
        return
    def ensure_unpack_false(uri):
        return ';'.join([x for x in uri.split(';') if not x.startswith('unpack=')] + ['unpack=false'])
    src_uri = [ensure_unpack_false(uri) for uri in src_uri]
    d.setVar('SRC_URI', ' '.join(src_uri))
}

deltask dpkg_build
addtask unpack before do_deploy_deb
