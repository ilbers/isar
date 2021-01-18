# Example of a custom initramfs image recipe.  The image will be deployed to
#
#   build/tmp/deploy/images/${MACHINE}/isar-initramfs-${DISTRO}-${MACHINE}.initrd.img
#
# This software is a part of ISAR.

inherit initramfs

# Debian packages that should be installed into the system for building the
# initramfs.  E.g. the cryptsetup package which contains initramfs scripts for
# decrypting a root filesystem.
INITRAMFS_PREINSTALL += " \
    "

# Recipes that should be installed into the initramfs build rootfs.
INITRAMFS_INSTALL += " \
    initramfs-example \
    "
