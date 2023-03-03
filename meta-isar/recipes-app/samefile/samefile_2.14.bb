# This software is a part of ISAR.
# Copyright (c) Siemens AG, 2019
#
# SPDX-License-Identifier: MIT

inherit dpkg

DEBIAN_DEPENDS = "\${misc:Depends}"
DESCRIPTION = "utility that finds files with identical contents"

# These variables allow more control, read the classes to find the default
# values, or check bitbake -e
# MAINTAINER CHANGELOG_V DPKG_ARCH

SRC_URI = "http://www.schweikhardt.net/samefile-2.14.tar.gz"
SRC_URI[md5sum] = "0b438249f3549f18b49cbb49b0473f70"

do_prepare_build[cleandirs] += "${S}/debian"
do_prepare_build() {
    # You could also create parts of your debianization before calling
    # deb_debianize. Pre-exisiting files will not be recreated, changelog
    # will be prepended unless its latest entry is for CHANGELOG_V.
    cat << EOF > ${WORKDIR}/changelog
${BPN} (0.1) unstable; urgency=low

  * a long long time ago there was an early version

 -- ${MAINTAINER}  Thu, 24 Dec 1970 00:00:00 +0100
EOF

    # Hooks should be placed into WORKDIR before calling deb_debianize.
    cat << EOF > ${WORKDIR}/postinst
#!/bin/sh
echo "" >&2
echo "NOTE: This package was built by Isar." >&2
echo "" >&2
EOF

    # This step creates everything dpkg-buildpackage needs. For further details
    # you might want to look at its implementation.
    deb_debianize

    # We can also customize afterwards, in this case change the package section.
    sed -i -e 's/Section: misc/Section: utils/g' ${S}/debian/control
}
