# squashfs image rootfs
#
# This software is a part of ISAR.
# Copyright (C) Siemens AG, 2021-2025
#
# SPDX-License-Identifier: MIT

def get_free_mem():
    try:
        with open('/proc/meminfo') as meminfo:
            lines = meminfo.readlines()
            for line in lines:
                if line.startswith('MemAvailable:'):
                    return int(line.split()[1]) * 1024
    except FileNotFoundError:
        pass
    return 4*1024*1024*1024  # 4G

IMAGER_INSTALL:squashfs += "squashfs-tools"

SQUASHFS_EXCLUDE_DIRS ?= ""
SQUASHFS_CONTENT ?= "${PP_ROOTFS}"
SQUASHFS_CREATION_ARGS ?= ""

SQUASHFS_THREADS ?= "${@oe.utils.cpu_count(at_least=2)}"
SQUASHFS_MEMLIMIT ?= "${@int(get_free_mem() * 3/4)}"
SQUASHFS_CREATION_LIMITS = "-mem ${SQUASHFS_MEMLIMIT} -processors ${SQUASHFS_THREADS}"

python __anonymous() {
    exclude_directories = d.getVar('SQUASHFS_EXCLUDE_DIRS').split()
    if len(exclude_directories) == 0:
        return
    # Use wildcard to exclude only content of the directory.
    # This allows to use the directory as a mount point.
    args = " -wildcards"
    for dir in exclude_directories:
        args += " -e '{dir}/*' ".format(dir=dir)
    d.appendVar('SQUASHFS_CREATION_ARGS', args)
}

IMAGE_CMD:squashfs[depends] = "${PN}:do_transform_template"
IMAGE_CMD:squashfs[vardepsexclude] += "SQUASHFS_CREATION_LIMITS"
IMAGE_CMD:squashfs() {
    ${SUDO_CHROOT} /bin/mksquashfs \
        '${SQUASHFS_CONTENT}' '${IMAGE_FILE_CHROOT}' \
        -noappend ${SQUASHFS_CREATION_LIMITS} ${SQUASHFS_CREATION_ARGS}
}
