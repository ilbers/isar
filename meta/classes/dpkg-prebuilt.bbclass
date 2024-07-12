# This software is a part of ISAR.
# Copyright (C) 2021-2022 Siemens AG
#
# SPDX-License-Identifier: MIT

inherit dpkg-base

python do_unpack:prepend() {
    # enforce unpack=false
    src_uri_raw = d.getVar('SRC_URI', False)
    src_uri_exp = (d.getVar('SRC_URI', True) or '').split()
    if len(src_uri_exp) == 0:
        return
    def ensure_unpack_false(uri):
        return ';'.join([x for x in uri.split(';') if not x.startswith('unpack=')] + ['unpack=false'])
    src_uri = [ensure_unpack_false(uri) for uri in src_uri_exp]
    d.setVar('SRC_URI', ' '.join(src_uri))
    if src_uri_raw:
        d.appendVarFlag('SRC_URI', 'vardepvalue', src_uri_raw)
}

# also breaks inherited (from dpkg-base) dependency on sbuild_chroot
do_dpkg_build[depends] = "${PN}:do_unpack"
do_dpkg_build() {
    # ensure all packages we got are valid debian packages
    if [ -n "$(find ${WORKDIR} -maxdepth 1 -name '*.deb' -print -quit)" ]; then
        find ${WORKDIR} -name '*.deb' | xargs -n1 dpkg -I
    fi
}
