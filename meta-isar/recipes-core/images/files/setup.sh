#!/bin/sh
#
# This software is a part of ISAR.
# Copyright (C) 2015-2016 ilbers GmbH
#
# Based on multistrap/examples/chroot.sh

set -e

# The script is called with the following arguments:
# $1 = $DIR  - the top directory of the bootstrapped system
# $2 = $ARCH - the specified architecture, already checked with
# dpkg-architecture.
# setup.sh needs to be executable.

TARGET=$1

# Prevent daemons from starting in postinstall during the initial "dpkg
# --configure -a" under QEMU on the build host
if [ -x "$TARGET/sbin/start-stop-daemon" ]; then
    echo "initctl: Trying to prevent daemons from starting in $TARGET"

    # Disable start-stop-daemon
    mv $TARGET/sbin/start-stop-daemon $TARGET/sbin/start-stop-daemon.REAL
    cat > $TARGET/sbin/start-stop-daemon << EOF
#!/bin/sh
echo
echo Warning: Fake start-stop-daemon called, doing nothing
EOF
    chmod 755 $TARGET/sbin/start-stop-daemon
fi

if [ -x "$TARGET/sbin/initctl" ]; then
    echo "start-stop-daemon: Trying to prevent daemons from starting in $TARGET"

    # Disable initctl
    mv "$TARGET/sbin/initctl" "$TARGET/sbin/initctl.REAL"
    cat > $TARGET/sbin/initctl << EOF
#!/bin/sh
echo
echo "Warning: Fake initctl called, doing nothing"
EOF
    chmod 755 $TARGET/sbin/initctl
fi

# Define sysvinit policy 101 to prevent daemons from starting in postinstall
# during the initial "dpkg --configure -a" under QEMU on the build host
if [ -x "$TARGET/sbin/init" -a ! -f "$TARGET/usr/sbin/policy-rc.d" ]; then
    echo "sysvinit: Using policy-rc.d to prevent daemons from starting in $TARGET"

    cat > $TARGET/usr/sbin/policy-rc.d << EOF
#!/bin/sh
echo "sysvinit: All runlevel operations denied by policy" >&2
exit 101
EOF
    chmod a+x $TARGET/usr/sbin/policy-rc.d
fi

# Install QEMU emulator to execute ARM binaries
sudo cp /usr/bin/qemu-arm-static ${TARGET}/usr/bin

# Set hostname
echo "isar" > $TARGET/etc/hostname
