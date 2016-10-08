isar - Integration System for Automated Root filesystem generation

Isar is a set of scripts for building software packages and repeatable
generation of Debian-based root filesystems with customizations.

# Build

1. Install and configure sudo (see TODO):

        # apt-get install sudo
        # visudo

   In the editor, allow the current user to run sudo without a password, e.g.:

        <user>  ALL=NOPASSWD: ALL

   Replace <user> with your user name. Use the tab character between <user> and
   parameters.

1. Initialize the build directory, e.g.:

        $ cd isar
        $ . isar-init-build-env ../build

1. Build the root filesystem image:

   Build isar base images for QEMU and RPi:

        $ bitbake multiconfig:qemuarm:isar-image-base multiconfig:rpi:isar-image-base

   Created images are:

        tmp/deploy/images/isar-image-base-qemuarm.ext4.img
        tmp/deploy/images/isar-image-base.rpi-sdimg

# Try

To test the QEMU image, run the following command:

        $ start_armhf_vm

The default root password is 'root'.

To test the RPi board, flash the image to an SD card using the insctructions from the official site,
section "WRITING AN IMAGE TO THE SD CARD":

    https://www.raspberrypi.org/documentation/installation/installing-images/README.md

# Release Information

Built on:
* Debian 8.2

Tested on:
* QEMU 1.1.2+dfsg-6a+deb7u12
* Raspberry Pi 1 Model B
