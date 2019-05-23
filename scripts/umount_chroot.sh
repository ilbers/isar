#!/bin/sh

umount $1/tmp
umount $1/proc
umount $1/sys
umount $1/dev/pts
umount $1/dev/shm
umount $1/dev
