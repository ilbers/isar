#!/bin/sh

set -e

#set up non-interactive configuration
export DEBIAN_FRONTEND=noninteractive DEBCONF_NONINTERACTIVE_SEEN=true
export LC_ALL=C LANGUAGE=C LANG=C
#run pre installation script
/var/lib/dpkg/info/dash.preinst install
#configuring packages
dpkg --configure -a
mount proc -t proc /proc
dpkg --configure -a
umount /proc

echo "root:root" |chpasswd
