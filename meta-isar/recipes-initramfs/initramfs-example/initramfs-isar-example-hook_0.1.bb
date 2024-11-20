# Example of a recipe containing an initramfs module.  Packages like this can be
# used with initramfs.bbclass or installed directly into a rootfs, depending on
# the usecase.
#
# This software is a part of ISAR.

require recipes-initramfs/initramfs-hook/hook.inc

DESCRIPTION = "Sample initramfs module for ISAR"
MAINTAINER = "Your name here <you@domain.com>"

# If the conf-hook enables BUSYBOX=y, busybox is needed:
DEBIAN_DEPENDS .= ", busybox"

SRC_URI += " \
    file://example.conf-hook \
    file://local-top \
    "

do_install[cleandirs] += " \
    ${D}/usr/share/initramfs-tools/conf-hooks.d \
    "
do_install:append() {
    # See "CONFIGURATION HOOK SCRIPTS" in initramfs-tools(7) for details.
    install "${WORKDIR}/example.conf-hook" \
        "${D}/usr/share/initramfs-tools/conf-hooks.d/isar-example"

    # See "HOOK SCRIPTS" in initramfs-tools(7) for details on
    # hook-header[.tmpl] + hook.

    # Note that there are other places where a boot script might be deployed to,
    # apart from local-top.  See "BOOT SCRIPTS" in initramfs-tools(7) for details.
}
