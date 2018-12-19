#!/usr/bin/env sh

echo -n "SSH server is "
if systemctl is-enabled ssh; then
    SSHD_ENABLED="true"
    systemctl disable --no-reload ssh
fi

echo "Removing keys ..."
rm -v /etc/ssh/ssh_host_*_key*

echo "Regenerating keys ..."
dpkg-reconfigure openssh-server

if test -n $SSHD_ENABLED; then
    echo "Reenabling ssh server ..."
    systemctl enable --no-reload ssh
fi
