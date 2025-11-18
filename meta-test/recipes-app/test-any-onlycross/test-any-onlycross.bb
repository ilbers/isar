# Test package using dpkg-raw, which breaks when trying to cross
# compile

#MAINTAINER = "Your name here <you@domain.com>"

SRC_URI = "file://rules"

inherit dpkg-raw
DPKG_ARCH = "any"

do_install() {
	bbnote "Test \"any\" package which fails native compile."
}
