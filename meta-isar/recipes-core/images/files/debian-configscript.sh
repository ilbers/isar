#!/bin/sh
#
# This software is a part of ISAR.
# Copyright (C) 2015-2017 ilbers GmbH

set -e

readonly MACHINE_SERIAL="$1"
readonly BAUDRATE_TTY="$2"
readonly ROOTFS_DEV="$3"
readonly ROOTFS_TYPE="$4"

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

# Create console device
if [ ! -e /dev/console ]; then
     mknod /dev/console c 5 1
fi

# Enable tty conditionally, systemd does not have the file but its own magic
if [ -f /etc/inittab ]; then
    echo "T0:23:respawn:/sbin/getty -L $MACHINE_SERIAL $BAUDRATE_TTY vt100" \
        >> /etc/inittab
fi

# Purge unused locale and installed packages' .deb files
localepurge
