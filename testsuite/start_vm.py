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

from utils import CIUtils

OVMF_VARS_PATH = '/usr/share/OVMF/OVMF_VARS_4M.ms.fd'


def format_qemu_cmdline(
    arch, build, distro, image, out, pid, enforce_pcbios=False
):
    multiconfig = f"mc:qemu{arch}-{distro}:{image}"

    (
        image_fstypes,
        deploy_dir_image,
        kernel_image,
        initrd_image,
        serial,
        root_dev,
        qemu_arch,
        qemu_machine,
        qemu_cpu,
        qemu_disk_args,
    ) = CIUtils.getVars(
        'IMAGE_FSTYPES',
        'DEPLOY_DIR_IMAGE',
        'KERNEL_IMAGE',
        'INITRD_DEPLOY_FILE',
        'MACHINE_SERIAL',
        'QEMU_ROOTFS_DEV',
        'QEMU_ARCH',
        'QEMU_MACHINE',
        'QEMU_CPU',
        'QEMU_DISK_ARGS',
        target=multiconfig,
    )

    extra_args = ''

    image_type = image_fstypes.split()[0]
    base = 'ubuntu' if distro in ['jammy', 'focal', 'noble'] else 'debian'

    rootfs_image = f"{image}-{base}-{distro}-qemu{arch}.{image_type}"

    if image_type == 'ext4':
        kernel_image = deploy_dir_image + '/' + kernel_image

        if not initrd_image:
            initrd_image = '/dev/null'
        else:
            initrd_image = deploy_dir_image + '/' + initrd_image

        kargs = ['-append', f'"console={serial} root=/dev/{root_dev} rw"']

        extra_args = ['-kernel', kernel_image, '-initrd', initrd_image]
        extra_args.extend(kargs)
    elif image_type == 'wic':
        extra_args = ['-snapshot']
    else:
        raise ValueError(f"Invalid image type: {str(image_type)}")

    if out:
        extra_args.extend(['-chardev', 'stdio,id=ch0,logfile=' + out])
        extra_args.extend(['-serial', 'chardev:ch0'])
        extra_args.extend(['-monitor', 'none'])
    if pid:
        extra_args.extend(['-pidfile', pid])

    rootfs_path = os.path.join(deploy_dir_image, rootfs_image)
    qemu_disk_args = qemu_disk_args.replace('##ROOTFS_IMAGE##', rootfs_path)
    qemu_disk_args = qemu_disk_args.split()
    if enforce_pcbios and '-bios' in qemu_disk_args:
        bios_idx = qemu_disk_args.index('-bios')
        del qemu_disk_args[bios_idx : bios_idx + 2]

    # Support SSH access from host
    ssh_sock = socket.socket()
    ssh_sock.bind(('', 0))
    ssh_port = ssh_sock.getsockname()[1]
    extra_args.extend(['-device', 'e1000,netdev=net0'])
    extra_args.extend(
        ['-netdev', 'user,id=net0,hostfwd=tcp::' + str(ssh_port) + '-:22']
    )

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
                print(
                    f"{OVMF_VARS_PATH} required but not found!",
                    file=sys.stderr,
                )
                break
            shutil.copy(OVMF_VARS_PATH, ovmf_vars_filename)
            return True

    return False


def sb_cleanup():
    os.remove(os.path.basename(OVMF_VARS_PATH))


def start_qemu(arch, build, distro, image, out, pid, enforce_pcbios):
    cmdline = format_qemu_cmdline(
        arch, build, distro, image, out, pid, enforce_pcbios
    )
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
    arch_names = ['arm', 'arm64', 'amd64', 'amd64-sb', 'amd64-cip', 'amd64-iso', 'i386', 'mipsel']
    distro_names = [
        'buster',
        'bullseye',
        'bookworm',
        'trixie',
        'focal',
        'jammy',
        'noble',
    ]
    parser.add_argument(
        '-a',
        '--arch',
        choices=arch_names,
        help='set isar machine architecture.',
        default='arm',
    )
    parser.add_argument(
        '-b',
        '--build',
        help='set path to build directory.',
        default=os.getcwd(),
    )
    parser.add_argument(
        '-d',
        '--distro',
        choices=distro_names,
        help='set isar Debian distribution.',
        default='bookworm',
    )
    parser.add_argument(
        '-i', '--image', help='set image name.', default='isar-image-base'
    )
    parser.add_argument(
        '-o', '--out', help='Route QEMU console output to specified file.'
    )
    parser.add_argument(
        '-p', '--pid', help='Store QEMU pid to specified file.'
    )
    parser.add_argument(
        '--pcbios',
        action='store_true',
        help='remove any ' 'bios options to enforce use of pc bios',
    )
    return parser.parse_args()


if __name__ == '__main__':
    args = parse_args()

    start_qemu(
        args.arch,
        args.build,
        args.distro,
        args.image,
        args.out,
        args.pid,
        args.pcbios,
    )
