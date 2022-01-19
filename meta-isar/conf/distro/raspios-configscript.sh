#!/bin/sh
#
# This software is a part of ISAR.
# Copyright (C) 2022 ilbers GmbH

set -e

readonly MACHINE_SERIAL="$1"
readonly BAUDRATE_TTY="$2"

cat > /boot/config.txt << EOF
[pi3]
# Restore UART0/ttyAMA0 over GPIOs 14 & 15
dtoverlay=miniuart-bt

[all]
EOF

cat > /boot/cmdline.txt << EOF
console=${MACHINE_SERIAL},${BAUDRATE_TTY} console=tty1 \
root=/dev/mmcblk0p2 rootfstype=ext4 fsck.repair=yes \
rootwait quiet init=/usr/lib/raspi-config/init_resize.sh
EOF

cat > /etc/fstab << EOF
proc            /proc           proc    defaults          0       0
/dev/mmcblk0p1  /boot           vfat    defaults          0       2
/dev/mmcblk0p2  /               ext4    defaults,noatime  0       1
EOF

cat > /etc/init.d/resize2fs_once << EOF
#!/bin/sh
. /lib/lsb/init-functions
case "\$1" in
  start)
    log_daemon_msg "Starting resize2fs_once"
    ROOT_DEV=\$(findmnt / -o source -n) &&
    resize2fs \$ROOT_DEV &&
    update-rc.d resize2fs_once remove &&
    rm /etc/init.d/resize2fs_once &&
    log_end_msg \$?
    ;;
  *)
    echo "Usage: \$0 start" >&2
    exit 3
    ;;
esac
EOF
chmod +x /etc/init.d/resize2fs_once
ln -s ../init.d/resize2fs_once /etc/rc3.d/S01resize2fs_once
