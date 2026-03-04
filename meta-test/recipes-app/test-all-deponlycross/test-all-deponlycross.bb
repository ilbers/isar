# Test all package using dpkg-raw

SRC_URI = "file://rules"

inherit dpkg-raw

MAINTAINER = "isar-users <isar-users@googlegroups.com>"

DEPENDS = "test-any-onlycross"

do_install() {
	bbnote "Test \"all\" package which depends on an any package."
}
