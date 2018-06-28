isar - Integration System for Automated Root filesystem generation

Isar is a set of scripts for building software packages and repeatable
generation of Debian-based root filesystems with customizations.

# Download

https://github.com/ilbers/isar/

# Build

Instruction on how to build can be found in the [User Manual](doc/user_manual.md).


# Try

To test the QEMU image, run the following command:

        $ start_vm -a arm -d jessie

The default root password is 'root'.

To test the RPi board, flash the image to an SD card using the instructions from the official site,
section "WRITING AN IMAGE TO THE SD CARD":
 https://www.raspberrypi.org/documentation/installation/installing-images/README.md

# Support

Mailing lists:

* Using Isar: https://groups.google.com/d/forum/isar-users
  * Subscribe: isar-users+subscribe@googlegroups.com
  * Unsubscribe: isar-users+unsubscribe@googlegroups.com

* Collaboration: https://lists.debian.org/debian-embedded/
  * Subscribe: debian-embedded-request@lists.debian.org, Subject: subscribe
  * Unsubscribe: debian-embedded-request@lists.debian.org, Subject: unsubscribe

Commercial support: info@ilbers.de

# Credits

* Developed by ilbers GmbH & Siemens AG
* Sponsored by Siemens AG
