#!/bin/sh

set -e

mount /tmp     $1/tmp                 -o bind
mount proc     $1/proc    -t proc     -o nosuid,noexec,nodev
mount sysfs    $1/sys     -t sysfs    -o nosuid,noexec,nodev
mount devtmpfs $1/dev     -t devtmpfs -o mode=0755,nosuid
mount devpts   $1/dev/pts -t devpts   -o gid=5,mode=620
mount tmpfs    $1/dev/shm -t tmpfs    -o rw,seclabel,nosuid,nodev
