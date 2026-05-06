# test package generating both arch=all and arch=any binary packages
DPKG_ARCH = "any"
SRC_URI = "file://control"

MAINTAINER = "isar-users <isar-users@googlegroups.com>"

inherit dpkg-raw

PROVIDES += "test-all-any-doc-archall"

do_prepare_build:append() {
    cp ${WORKDIR}/control ${S}/debian/
}
