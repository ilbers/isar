# Test package using dpkg-raw to install a file into /install.

inherit dpkg-raw

do_install[cleandirs] += "${D}/install"

do_install() {
    printf '%s\n' 'test payload' > "${D}/install/test-rootfs-add-files"
}
