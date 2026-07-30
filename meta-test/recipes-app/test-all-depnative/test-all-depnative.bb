# Test all package depending on an arch=all package provided via -archall.

SRC_URI = "file://rules"

inherit dpkg-raw

MAINTAINER = "isar-users <isar-users@googlegroups.com>"

DEPENDS = "test-all-any-doc"

do_install() {
	bbnote "Test \"all\" package depending on an arch=all (-archall) package."
}
