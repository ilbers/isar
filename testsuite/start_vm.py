#!/usr/bin/env python3
#
# Helper script to start QEMU with Isar image
# Copyright (c) 2019, ilbers GmbH

import argparse
import os
import subprocess
import sys
import time

def get_bitbake_env(arch, distro):
    multiconfig = 'mc:qemu' + arch + '-' + distro + ':isar-image-base'
    output = subprocess.check_output(['bitbake', '-e', str(multiconfig)])
    return output

def get_bitbake_var(output, var):
    ret = ''
    for line in output.splitlines():
        if line.startswith(var):
            ret = line.split('"')[1]
    return ret

def format_qemu_cmdline(arch, build, distro):
    bb_output = get_bitbake_env(arch, distro).decode()

    rootfs_image = ''
    extra_args = ''
    cpu = ['']

    image_type = get_bitbake_var(bb_output, 'IMAGE_TYPE')
    deploy_dir_image = get_bitbake_var(bb_output, 'DEPLOY_DIR_IMAGE')
    if image_type == 'ext4-img':
        rootfs_image = 'isar-image-base-debian-' + distro + '-qemu' + arch + '.ext4.img'
        kernel_image = deploy_dir_image + '/' + get_bitbake_var(bb_output, 'KERNEL_IMAGE')
        initrd_image = get_bitbake_var(bb_output, 'INITRD_IMAGE')

        if not initrd_image:
            initrd_image = '/dev/null'
        else:
            initrd_image = deploy_dir_image + '/' + initrd_image

        serial = get_bitbake_var(bb_output, 'MACHINE_SERIAL')
        root_dev = get_bitbake_var(bb_output, 'QEMU_ROOTFS_DEV')
        kargs = ['-append', '"console=' + serial + ' root=/dev/' + root_dev + ' rw"']

        extra_args = ['-kernel', kernel_image, '-initrd', initrd_image]
        extra_args.extend(kargs)
    elif image_type == 'wic-img':
        rootfs_image = 'isar-image-base-debian-' + distro + '-qemu' + arch + '.wic.img'
        extra_args = ['-snapshot']
    else:
        raise ValueError('Invalid image type: ' + str(image_type))

    qemu_arch = get_bitbake_var(bb_output, 'QEMU_ARCH')
    qemu_machine = get_bitbake_var(bb_output, 'QEMU_MACHINE')
    qemu_cpu = get_bitbake_var(bb_output, 'QEMU_CPU')
    qemu_disk_args = get_bitbake_var(bb_output, 'QEMU_DISK_ARGS')

    qemu_disk_args = qemu_disk_args.replace('##ROOTFS_IMAGE##', deploy_dir_image + '/' + rootfs_image).split()

    cmd = ['qemu-system-' + qemu_arch, '-m', '1024M']

    if qemu_machine:
        cmd.extend(['-M', qemu_machine])

    if qemu_cpu:
        cmd.extend(['-cpu', qemu_cpu])

    cmd.extend(extra_args)
    cmd.extend(qemu_disk_args)

    return cmd

def start_qemu(arch, build, distro):
    cmdline = format_qemu_cmdline(arch, build, distro)
    cmdline.insert(1, '-nographic')

    p1 = subprocess.call(cmdline)

if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument('-a', '--arch', choices=['arm', 'arm64', 'amd64', 'i386'], help='set isar machine architecture.', default='arm')
    parser.add_argument('-b', '--build', help='set path to build directory.', default=os.getcwd())
    parser.add_argument('-d', '--distro', choices=['jessie', 'stretch'], help='set isar Debian distribution.', default='stretch')
    args = parser.parse_args()

    start_qemu(args.arch, args.build, args.distro)
