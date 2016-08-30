isar - Integration System for Automated Root filesystem generation

Isar is a set of scripts for building software packages and repeatable
generation of Debian-based root filesystems with customizations.

Copyright (c) 2016 ilbers GmbH

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
        $ . isar-init-build-env build

1. Build the root filesystem image:

        $ bitbake isar-image-base

Created image is in

    tmp/deploy/images/isar-image-base.ext4.img

# Test

Test the image with QEMU:

        $ cd scripts
        $ ./start-isar-qemuarm ../build

Check test application:

        $ hello
        Hello, world!
