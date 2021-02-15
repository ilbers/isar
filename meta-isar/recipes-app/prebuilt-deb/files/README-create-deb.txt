Create test deb package:

mkdir -p example-prebuilt/DEBIAN example-prebuilt/opt
cat << EOF > example-prebuilt/DEBIAN/control
Section: misc
Priority: optional
Package: example-prebuilt
Version: 1.0.0
Maintainer: Who Knows <who.knows@example.com>
Description: Just a test package
Architecture: all
EOF
echo "Just some test content" > example-prebuilt/opt/some-package-file
dpkg -b example-prebuilt example-prebuilt_1.0.0-0_all.deb
