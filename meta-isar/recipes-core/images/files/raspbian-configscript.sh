#!/bin/sh
#
# This software is a part of ISAR.
# Copyright (C) 2015-2017 ilbers GmbH

set -e

readonly MACHINE_SERIAL="$1"
readonly BAUDRATE_TTY="$2"
readonly ROOTFS_DEV="$3"
readonly ROOTFS_TYPE="$4"

cat >> /etc/default/locale << EOF
LANG=en_US.UTF-8
LANGUAGE=en_US.UTF-8
LC_ALL=C
LC_CTYPE=C
EOF

## Configuration file for localepurge(8)
cat > /etc/locale.nopurge << EOF

# Remove localized man pages
MANDELETE

# Delete new locales which appear on the system without bothering you
DONTBOTHERNEWLOCALE

# Keep these locales after package installations via apt-get(8)
en
en_US
en_US.UTF-8
EOF

debconf-set-selections <<END
locales locales/locales_to_be_generated multiselect en_US.UTF-8 UTF-8
locales locales/default_environment_locale select en_US.UTF-8
END

cat > /etc/fstab << EOF
# Begin /etc/fstab
/dev/$ROOTFS_DEV	/		$ROOTFS_TYPE		defaults		1	1
proc		/proc		proc		nosuid,noexec,nodev	0	0
sysfs		/sys		sysfs		nosuid,noexec,nodev	0	0
devpts		/dev/pts	devpts		gid=5,mode=620		0	0
tmpfs		/run		tmpfs		defaults		0	0
devtmpfs	/dev		devtmpfs	mode=0755,nosuid	0	0

# End /etc/fstab
EOF

# Enable tty conditionally, systemd does not have the file but its own magic
if [ -f /etc/inittab ]; then
    echo "T0:23:respawn:/sbin/getty -L $MACHINE_SERIAL $BAUDRATE_TTY vt100" \
        >> /etc/inittab
fi

KERNEL_IMAGE=`ls /boot | grep vmlinuz`

cat > /boot/config.txt << EOF
kernel=$KERNEL_IMAGE
EOF

localepurge
apt-get clean
