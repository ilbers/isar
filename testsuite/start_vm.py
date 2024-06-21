#!/usr/bin/env python3
#
# Helper script to start QEMU with Isar image
# Copyright (c) 2019-2024, ilbers GmbH

import argparse
import os
import socket
import subprocess
import sys
import shutil
import time

OVMF_VARS_PATH = '/usr/share/OVMF/OVMF_VARS_4M.ms.fd'

def get_bitbake_env(arch, distro, image):
    multiconfig = 'mc:qemu' + arch + '-' + distro + ':' + image
    output = subprocess.check_output(['bitbake', '-e', str(multiconfig)])
    return output

def get_bitbake_var(output, var):
    ret = ''
    for line in output.splitlines():
        if line.startswith(var + '='):
            ret = line.split('"')[1]
    return ret

def format_qemu_cmdline(arch, build, distro, image, out, pid, enforce_pcbios=False):
    bb_output = get_bitbake_env(arch, distro, image).decode()

    extra_args = ''
    cpu = ['']

    image_type = get_bitbake_var(bb_output, 'IMAGE_FSTYPES').split()[0]
    deploy_dir_image = get_bitbake_var(bb_output, 'DEPLOY_DIR_IMAGE')
    base = 'ubuntu' if distro in ['jammy', 'focal'] else 'debian'

    rootfs_image = image + '-' + base + '-' + distro + '-qemu' + arch + '.' + image_type

    if image_type == 'ext4':
        kernel_image = deploy_dir_image + '/' + get_bitbake_var(bb_output, 'KERNEL_IMAGE')
        initrd_image = get_bitbake_var(bb_output, 'INITRD_DEPLOY_FILE')

        if not initrd_image:
            initrd_image = '/dev/null'
        else:
            initrd_image = deploy_dir_image + '/' + initrd_image

        serial = get_bitbake_var(bb_output, 'MACHINE_SERIAL')
        root_dev = get_bitbake_var(bb_output, 'QEMU_ROOTFS_DEV')
        kargs = ['-append', '"console=' + serial + ' root=/dev/' + root_dev + ' rw"']

        extra_args = ['-kernel', kernel_image, '-initrd', initrd_image]
        extra_args.extend(kargs)
    elif image_type == 'wic':
        extra_args = ['-snapshot']
    else:
        raise ValueError('Invalid image type: ' + str(image_type))

    qemu_arch = get_bitbake_var(bb_output, 'QEMU_ARCH')
    qemu_machine = get_bitbake_var(bb_output, 'QEMU_MACHINE')
    qemu_cpu = get_bitbake_var(bb_output, 'QEMU_CPU')
    qemu_disk_args = get_bitbake_var(bb_output, 'QEMU_DISK_ARGS')

    if out:
        extra_args.extend(['-chardev','stdio,id=ch0,logfile=' + out])
        extra_args.extend(['-serial','chardev:ch0'])
        extra_args.extend(['-monitor','none'])
    if pid:
        extra_args.extend(['-pidfile', pid])

    qemu_disk_args = qemu_disk_args.replace('##ROOTFS_IMAGE##', deploy_dir_image + '/' + rootfs_image).split()
    if enforce_pcbios and '-bios' in qemu_disk_args:
        bios_idx = qemu_disk_args.index('-bios')
        del qemu_disk_args[bios_idx : bios_idx+2]

    # Support SSH access from host
    ssh_sock = socket.socket()
    ssh_sock.bind(('', 0))
    ssh_port=ssh_sock.getsockname()[1]
    extra_args.extend(['-device', 'e1000,netdev=net0'])
    extra_args.extend(['-netdev', 'user,id=net0,hostfwd=tcp::' + str(ssh_port) + '-:22'])

    cmd = ['qemu-system-' + qemu_arch, '-m', '1024M']

    if qemu_machine:
        cmd.extend(['-M', qemu_machine])

    if qemu_cpu:
        cmd.extend(['-cpu', qemu_cpu])

    cmd.extend(extra_args)
    cmd.extend(qemu_disk_args)

    return cmd


def sb_copy_vars(cmdline):
    ovmf_vars_filename = os.path.basename(OVMF_VARS_PATH)

    for param in cmdline:
        if ovmf_vars_filename in param:
            if os.path.exists(ovmf_vars_filename):
                break
            if not os.path.exists(OVMF_VARS_PATH):
                print(f'{OVMF_VARS_PATH} required but not found!',
                      file=sys.stderr)
                break
            shutil.copy(OVMF_VARS_PATH, ovmf_vars_filename)
            return True

    return False


def sb_cleanup():
    os.remove(os.path.basename(OVMF_VARS_PATH))


def start_qemu(arch, build, distro, image, out, pid, enforce_pcbios):
    cmdline = format_qemu_cmdline(arch, build, distro, image, out, pid, enforce_pcbios)
    cmdline.insert(1, '-nographic')

    need_cleanup = sb_copy_vars(cmdline)

    print(cmdline)

    try:
        subprocess.call('exec ' + ' '.join(cmdline), shell=True)
    finally:
        if need_cleanup:
            sb_cleanup()


def parse_args():
    parser = argparse.ArgumentParser()
    arch_names = ['arm', 'arm64', 'amd64', 'amd64-sb', 'i386', 'mipsel']
    parser.add_argument('-a', '--arch', choices=arch_names,
                        help='set isar machine architecture.', default='arm')
    parser.add_argument('-b', '--build', help='set path to build directory.', default=os.getcwd())
    parser.add_argument('-d', '--distro', choices=['buster', 'bullseye', 'bookworm', 'trixie', 'focal', 'jammy'], help='set isar Debian distribution.', default='bookworm')
    parser.add_argument('-i', '--image', help='set image name.', default='isar-image-base')
    parser.add_argument('-o', '--out', help='Route QEMU console output to specified file.')
    parser.add_argument('-p', '--pid', help='Store QEMU pid to specified file.')
    parser.add_argument('--pcbios', action="store_true", help='remove any bios options to enforce use of pc bios')
    return parser.parse_args()

if __name__ == "__main__":
    args = parse_args()

    start_qemu(args.arch, args.build, args.distro, args.image, args.out, args.pid, args.pcbios)
