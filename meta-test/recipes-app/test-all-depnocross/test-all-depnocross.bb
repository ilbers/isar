# Test package using dpkg-raw

SRC_URI = "file://rules"

inherit dpkg-raw

DEPENDS = "test-any-nocross"

do_install() {
	bbnote "Test \"all\" package which depends on an any package."
}
