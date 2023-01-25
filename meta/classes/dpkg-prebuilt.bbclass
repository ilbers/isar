# This software is a part of ISAR.
# Copyright (C) 2021-2022 Siemens AG
#
# SPDX-License-Identifier: MIT

inherit dpkg-base

python do_unpack:prepend() {
    # enforce unpack=false
    src_uri = (d.getVar('SRC_URI', False) or '').split()
    if len(src_uri) == 0:
        return
    def ensure_unpack_false(uri):
        return ';'.join([x for x in uri.split(';') if not x.startswith('unpack=')] + ['unpack=false'])
    src_uri = [ensure_unpack_false(uri) for uri in src_uri]
    d.setVar('SRC_URI', ' '.join(src_uri))
}

# break dependencies on do_patch, etc... but still support sstate caching
deltask dpkg_build
addtask dpkg_build after do_unpack before do_deploy_deb
# break inherited (from dpkg-base) dependency on sbuild_chroot
do_dpkg_build[depends] = ""
do_dpkg_build() {
    true
}
