#!/bin/sh
#
# Based on multistrap/examples/chroot.sh

set -e

echo "Configuring rootfs..."

HOSTNAME="isar"

# The script is called with the following arguments:
# $1 = $DIR  - the top directory of the bootstrapped system
# $2 = $ARCH - the specified architecture, already checked with
# dpkg-architecture.
# setup.sh needs to be executable.

TARGET=$1

# upstart support
if [ -x "$TARGET/sbin/initctl" ]; then
        echo "initctl: Trying to prevent daemons from starting in $TARGET"
        mv "$TARGET/sbin/start-stop-daemon" \
            "$TARGET/sbin/start-stop-daemon.REAL"
        echo \
"#!/bin/sh
echo
echo \"Warning: Fake start-stop-daemon called, doing nothing\"" \
            >"$TARGET/sbin/start-stop-daemon"
        chmod 755 "$TARGET/sbin/start-stop-daemon"
fi
if [ -x "$TARGET/sbin/initctl" ]; then
        echo "initctl: Trying to prevent daemons from starting in $TARGET"
        mv "$TARGET/sbin/initctl" "$TARGET/sbin/initctl.REAL"
        echo \
"#!/bin/sh
echo
echo \"Warning: Fake initctl called, doing nothing\"" > "$TARGET/sbin/initctl"
        chmod 755 "$TARGET/sbin/initctl"
fi

# sysvinit support - exit value of 101 is essential.
if [ -x "$TARGET/sbin/init" -a ! -f "$TARGET/usr/sbin/policy-rc.d" ]; then
        echo "sysvinit: Using policy-rc.d to prevent daemons from starting" \
            "in $TARGET"
        mkdir -p $TARGET/usr/sbin/
        cat > $TARGET/usr/sbin/policy-rc.d << EOF
#!/bin/sh
echo "sysvinit: All runlevel operations denied by policy" >&2
exit 101
EOF
        chmod a+x $TARGET/usr/sbin/policy-rc.d
fi


sudo cp /usr/bin/qemu-arm-static ${TARGET}/usr/bin

echo ${HOSTNAME} >${TARGET}/etc/hostname
