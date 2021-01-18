# Example of a recipe containing an initramfs module.  Packages like this can be
# used with initramfs.bbclass or installed directly into a rootfs, depending on
# the usecase.
#
# This software is a part of ISAR.

DESCRIPTION = "Sample initramfs module for ISAR"
MAINTAINER = "Your name here <you@domain.com>"
DEBIAN_DEPENDS = "initramfs-tools"

# If the conf-hook enables BUSYBOX=y, busybox is needed:
DEBIAN_DEPENDS .= ", busybox"

SRC_URI = " \
    file://example.conf-hook \
    file://example.hook \
    file://example.script \
    "

inherit dpkg-raw

do_install[cleandirs] += " \
    ${D}/usr/share/initramfs-tools/conf-hooks.d \
    ${D}/usr/share/initramfs-tools/hooks \
    ${D}/usr/share/initramfs-tools/scripts/local-top \
    "
do_install() {
    # See "CONFIGURATION HOOK SCRIPTS" in initramfs-tools(7) for details.
    install "${WORKDIR}/example.conf-hook" \
        "${D}/usr/share/initramfs-tools/conf-hooks.d/isar-example"

    # See "HOOK SCRIPTS" in initramfs-tools(7) for details.
    install "${WORKDIR}/example.hook" \
        "${D}/usr/share/initramfs-tools/hooks/isar-example"

    # Note that there are other places where a boot script might be deployed to,
    # apart from local-top.  See "BOOT SCRIPTS" in initramfs-tools(7) for details.
    install "${WORKDIR}/example.script" \
        "${D}/usr/share/initramfs-tools/scripts/local-top/example.script"
}
