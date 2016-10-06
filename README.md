isar - Integration System for Automated Root filesystem generation

Isar is a set of scripts for building software packages and repeatable
generation of Debian-based root filesystems with customizations.

The 'meta-isar' layer provides support for two machines: QEMU and
Raspberry Pi.

Tested with: RPi 1b, QEMU 1.1.2+dfsg-6a+deb7u12.

# Build

1. Install and configure sudo (see TODO):

        # apt-get install sudo
        # visudo

   In the editor, allow the current user to run sudo without a password, e.g.:

        <user>  ALL=NOPASSWD: ALL

   Replace &lt;user> with your user name. Use the tab character between <user>
   and parameters.

1. Initialize the build directory, e.g.:

        $ cd isar
        $ . isar-init-build-env ../build

By default isar builds image for QEMU machine. To build for Raspberry Pi,
edit your config:

        # vim conf/local.conf

And replace "qemuarm" to "rpi" in MACHINE section.


1. Build the root filesystem image:

        $ bitbake isar-image-base

Created image is in

    tmp/deploy/images/isar-image-base-qemuarm.ext4.img

# Test

To test the QEMU image, run the following command:

        $ start_armhf_vm
