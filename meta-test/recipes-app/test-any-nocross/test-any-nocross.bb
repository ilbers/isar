# Test package using dpkg-raw, which breaks when trying to cross
# compile

SRC_URI = "file://rules"

inherit dpkg-raw
DPKG_ARCH = "any"

do_install() {
	bbnote "Test \"any\" package which fails crosscompile."
}
