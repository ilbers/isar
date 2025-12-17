#!/usr/bin/env python3
#
# This software is a part of ISAR.
# Copyright (C) 2022-2024 ilbers GmbH
# Copyright (C) 2022-2024 Siemens AG
#
# SPDX-License-Identifier: MIT

import logging
import os
import pickle
import re
import select
import shutil
import signal
import subprocess
import sys
import time
import tempfile

import start_vm
from utils import CIUtils

from avocado import Test
from avocado.utils import path
from avocado.utils import process

sys.path.append(os.path.join(os.path.dirname(__file__), '../bitbake/lib'))

import bb

DEF_VM_TO_SEC = 600

isar_root = os.path.abspath(os.path.join(os.path.dirname(__file__), '..'))
backup_prefix = '.ci-backup'

app_log = logging.getLogger('avocado.app')


class CanBeFinished(Exception):
    pass


class CIBuilder(Test):
    def setUp(self):
        super(CIBuilder, self).setUp()
        job_log = os.path.join(os.path.dirname(self.logdir), '..', 'job.log')
        self._file_handler = logging.FileHandler(filename=job_log)
        self._file_handler.setLevel(logging.ERROR)
        fmt = (
            '%(asctime)s %(module)-16.16s L%(lineno)-.4d '
            '%(levelname)-5.5s| %(message)s'
        )
        formatter = logging.Formatter(fmt=fmt)
        self._file_handler.setFormatter(formatter)
        app_log.addHandler(self._file_handler)

    def init(self, build_dir='build', isar_dir=isar_root):
        # initialize build_dir and setup environment
        # needs to run once (per test case)
        if hasattr(self, 'build_dir'):
            self.error(
                "Broken test implementation: init() called multiple times."
            )
        self.build_dir = os.path.join(isar_dir, build_dir)
        os.chdir(isar_dir)
        os.environ['TEMPLATECONF'] = 'meta-test/conf'
        path.usable_rw_dir(self.build_dir)
        output = process.getoutput(
            f"/bin/bash -c 'source isar-init-build-env {self.build_dir} 2>&1 "
            f">/dev/null; env'"
        )
        env = dict(
            (
                (x.split('=', 1) + [''])[:2]
                for x in output.splitlines()
                if x != ''
            )
        )
        os.environ.update(env)

        self.vm_dict = {}
        self.vm_dict_file = '%s/vm_dict_file' % self.build_dir

        if os.path.isfile(self.vm_dict_file):
            with open(self.vm_dict_file, 'rb') as f:
                data = f.read()
                if data:
                    self.vm_dict = pickle.loads(data)

    def check_init(self):
        if not hasattr(self, 'build_dir'):
            self.error("Broken test implementation: need to call init().")

    def configure(
        self,
        compat_arch=True,
        cross=True,
        debsrc_cache=False,
        container=False,
        ccache=False,
        sstate=False,
        offline=False,
        gpg_pub_key=None,
        wic_deploy_parts=False,
        dl_dir=None,
        sstate_dir=None,
        ccache_dir=None,
        source_date_epoch=None,
        use_apt_snapshot=False,
        image_install=None,
        installer_image=None,
        installer_machine=None,
        installer_distro=None,
        installer_device=None,
        customizations=None,
        lines=None,
        **kwargs,
    ):
        # write configuration file and set bitbake_args
        # can run multiple times per test case
        self.check_init()

        # get parameters from avocado cmdline
        quiet = bool(int(self.params.get('quiet', default=1)))

        if not sstate:
            sstate = bool(int(self.params.get('sstate', default=0)))

        # set those to "" to not set dir value but use system default
        if dl_dir is None:
            dl_dir = os.getenv('DL_DIR')
        if dl_dir is None:
            dl_dir = os.path.join(isar_root, 'downloads')
        if sstate_dir is None:
            sstate_dir = os.getenv('SSTATE_DIR')
        if sstate_dir is None:
            sstate_dir = os.path.join(isar_root, 'sstate-cache')
        if ccache_dir is None:
            ccache_dir = '${TOPDIR}/ccache'

        # get parameters from environment
        distro_apt_premir = os.getenv('DISTRO_APT_PREMIRRORS')
        fail_on_cleanup = os.getenv('ISAR_FAIL_ON_CLEANUP')

        strlines = None if lines is None else '\\n'.join(lines)
        self.log.info(
            f"===================================================\n"
            f"Configuring build_dir {self.build_dir}\n"
            f"  compat_arch = {compat_arch}\n"
            f"  cross = {cross}\n"
            f"  debsrc_cache = {debsrc_cache}\n"
            f"  offline = {offline}\n"
            f"  container = {container}\n"
            f"  ccache = {ccache}\n"
            f"  sstate = {sstate}\n"
            f"  gpg_pub_key = {gpg_pub_key}\n"
            f"  wic_deploy_parts = {wic_deploy_parts}\n"
            f"  source_date_epoch = {source_date_epoch} \n"
            f"  use_apt_snapshot = {use_apt_snapshot} \n"
            f"  dl_dir = {dl_dir}\n"
            f"  sstate_dir = {sstate_dir}\n"
            f"  ccache_dir = {ccache_dir}\n"
            f"  image_install = {image_install}\n"
            f"  installer_image = {installer_image}\n"
            f"  customizations = {customizations}\n"
            f"  lines = {strlines}\n"
            f"==================================================="
        )

        # determine bitbake_args
        self.bitbake_args = []
        if not quiet:
            self.bitbake_args.append('-v')
        if not sstate:
            self.bitbake_args.append('--no-setscene')

        # write ci_build.conf
        with open(self.build_dir + '/conf/ci_build.conf', 'w') as f:
            if compat_arch:
                f.write(
                    'ISAR_ENABLE_COMPAT_ARCH:amd64 = "1"\n'
                    'IMAGE_INSTALL:remove:amd64 = "hello-isar"\n'
                    'IMAGE_INSTALL:append:amd64 = " hello-isar-compat"\n'
                    'ISAR_ENABLE_COMPAT_ARCH:arm64 = "1"\n'
                    'IMAGE_INSTALL:remove:arm64 = "hello-isar"\n'
                    'IMAGE_INSTALL:append:arm64 = " hello-isar-compat"\n'
                )
            if not cross:
                f.write('ISAR_CROSS_COMPILE = "0"\n')
            else:
                f.write(
                    'ISAR_CROSS_COMPILE = "1"\n'
                    'IMAGE_INSTALL:append:hikey = '
                    '" linux-headers-${KERNEL_NAME}"\n'
                )
            if debsrc_cache:
                f.write('BASE_REPO_FEATURES = "cache-deb-src"\n')
            if offline:
                f.write(
                    'ISAR_USE_CACHED_BASE_REPO = "1"\n'
                    'BB_NO_NETWORK = "1"\n'
                )
            if container:
                f.write('SDK_FORMATS = "docker-archive"\n')
            if gpg_pub_key:
                f.write('BASE_REPO_KEY="file://' + gpg_pub_key + '"\n')
            if wic_deploy_parts:
                f.write('WIC_DEPLOY_PARTITIONS = "1"\n')
            if distro_apt_premir:
                f.write('DISTRO_APT_PREMIRRORS = "%s"\n' % distro_apt_premir)
            if ccache:
                f.write(
                    'USE_CCACHE = "1"\n'
                    'CCACHE_TOP_DIR = "%s"\n' % ccache_dir
                )
            if source_date_epoch:
                f.write(
                    'SOURCE_DATE_EPOCH_FALLBACK = "%s"\n' % source_date_epoch
                )
            if use_apt_snapshot:
                f.write('ISAR_USE_APT_SNAPSHOT = "1"\n')
            if dl_dir:
                f.write('DL_DIR = "%s"\n' % dl_dir)
            if sstate_dir:
                f.write('SSTATE_DIR = "%s"\n' % sstate_dir)
            if image_install is not None:
                f.write('IMAGE_INSTALL = "%s"\n' % image_install)
            if fail_on_cleanup == '1':
                f.write('ISAR_FAIL_ON_CLEANUP = "1"\n')
            if installer_image:
                install_target = self.build_dir + '/installer.wic'
                # Create empty file installer will write to
                with open(install_target, 'w') as wic:
                    size = 4294967296 # 4GiB should be enough for the target
                    wic.write("\0" * size)

                f.write(
                    'BBMULTICONFIG += "isar-installer installer-target"\n'
                    'INSTALLER_UNATTENDED = "1"\n'
                    'INSTALLER_TARGET_OVERWRITE = "OVERWRITE"\n'
                    f'INSTALLER_TARGET_IMAGE = "{installer_image}"\n'
                    f'INSTALLER_TARGET_DEVICE = "{installer_device}"\n'
                    f'DISTRO ?= "{installer_distro}"\n'
                    f'MACHINE ?= "{installer_machine}"\n'
                    'QEMU_DISK_ARGS = "-bios /usr/share/ovmf/OVMF.fd"\n'
                    f'QEMU_DISK_ARGS += "-drive file={install_target},'\
                        'if=ide,bus=0,unit=0,format=raw,snapshot=off"\n'
                    'QEMU_DISK_ARGS += "-hdb ##ROOTFS_IMAGE##"\n'
                )
            if customizations is not None:
                if not isinstance(customizations, str):
                    customizations = ' '.join(customizations)
                f.write(
                    f'CUSTOMIZATIONS = "{customizations}"\n'
                    'CUSTOMIZATION_VARS:append = " ${IMAGE}"\n'
                    'CUSTOMIZATION_FOR_IMAGES:append = " isar-image-ci"\n'
                    'HOSTNAME:isar-image-ci = "isar-ci"\n'
                )
            if lines is not None:
                f.writelines((line + '\n' if not line.endswith('\n') else line) for line in lines)

        # include ci_build.conf in local.conf
        with open(self.build_dir + '/conf/local.conf', 'r+') as f:
            for line in f:
                if 'include ci_build.conf' in line:
                    break
            else:
                f.write('\ninclude ci_build.conf')

    def unconfigure(self):
        self.check_init()
        open(self.build_dir + '/conf/ci_build.conf', 'w').close()

    def delete_from_build_dir(self, path):
        self.check_init()
        shutil.rmtree(self.build_dir + '/' + path, True)

    def move_in_build_dir(self, src, dst):
        self.check_init()
        if os.path.exists(self.build_dir + '/' + src):
            shutil.move(self.build_dir + '/' + src, self.build_dir + '/' + dst)

    def bitbake(self, target, bitbake_cmd=None, should_fail=False,
                sig_handler=None, bitbake_extra_args=[], **kwargs):
        self.check_init()
        self.log.info("===================================================")
        self.log.info(f"Building {str(target)}")
        self.log.info("===================================================")
        os.chdir(self.build_dir)
        cmdline = ['bitbake']
        if self.bitbake_args:
            cmdline.extend(self.bitbake_args)
        if bitbake_cmd:
            cmdline.append('-c')
            cmdline.append(bitbake_cmd)
        if sig_handler:
            cmdline.append('-S')
            cmdline.append(sig_handler)
        if bitbake_extra_args:
            cmdline.extend(bitbake_extra_args)
        if isinstance(target, list):
            cmdline.extend(target)
        else:
            cmdline.append(target)

        with subprocess.Popen(
            ' '.join(cmdline),
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
            universal_newlines=True,
            shell=True,
        ) as p1:
            poller = select.poll()
            poller.register(p1.stdout, select.POLLIN)
            poller.register(p1.stderr, select.POLLIN)
            while True:
                events = poller.poll(1000)
                for fd, event in events:
                    if event != select.POLLIN:
                        continue
                    if fd == p1.stdout.fileno():
                        self.log.info(p1.stdout.readline().rstrip())
                    if fd == p1.stderr.fileno() and should_fail is False:
                        app_log.error(p1.stderr.readline().rstrip())
                if p1.poll() is not None:
                    break
            p1.wait()
            if should_fail is False:
                if p1.returncode:
                    self.fail("Bitbake failed")
            elif p1.returncode == 0:
                self.fail("Bitbake suceeded but was expected to fail!")

    def backupfile(self, path):
        self.check_init()
        try:
            shutil.copy2(path, path + backup_prefix)
        except FileNotFoundError:
            self.log.warn(f"{path} not exist")

    def backupmove(self, path):
        self.check_init()
        try:
            shutil.move(path, path + backup_prefix)
        except FileNotFoundError:
            self.log.warn(f"{path} not exist")

    def restorefile(self, path):
        self.check_init()
        try:
            shutil.move(path + backup_prefix, path)
        except FileNotFoundError:
            self.log.warn(f"{path}{backup_prefix} not exist")

    def create_tmp_layer(self):
        tmp_layer_dir = os.path.join(isar_root, 'meta-tmp')

        conf_dir = os.path.join(tmp_layer_dir, 'conf')
        os.makedirs(conf_dir, exist_ok=True)
        layer_conf_file = os.path.join(conf_dir, 'layer.conf')
        with open(layer_conf_file, 'w') as file:
            file.write(
                'BBPATH .= ":${LAYERDIR}"\n'
                'BBFILES += "${LAYERDIR}/recipes-*/*/*.bbappend"\n'
                'BBFILE_COLLECTIONS += "tmp"\n'
                'BBFILE_PATTERN_tmp = "^${LAYERDIR}/"\n'
                'BBFILE_PRIORITY_tmp = "5"\n'
                'LAYERVERSION_tmp = "1"\n'
                'LAYERSERIES_COMPAT_tmp = "v0.6"\n'
            )

        bblayersconf_file = os.path.join(
            self.build_dir, 'conf', 'bblayers.conf'
        )
        bb.utils.edit_bblayers_conf(bblayersconf_file, tmp_layer_dir, None)

        return tmp_layer_dir

    def cleanup_tmp_layer(self, tmp_layer_dir):
        bblayersconf_file = os.path.join(
            self.build_dir, 'conf', 'bblayers.conf'
        )
        bb.utils.edit_bblayers_conf(bblayersconf_file, None, tmp_layer_dir)
        bb.utils.prunedir(tmp_layer_dir)

    def get_ssh_cmd_prefix(self, user, host, port, priv_key):
        cmd_prefix = (
            f"ssh -o ConnectTimeout=5 -o StrictHostKeyChecking=no -p {port} "
            f"-o IdentityFile={priv_key} {user}@{host}"
        )

        return cmd_prefix

    def exec_cmd(self, cmd, cmd_prefix):
        proc = subprocess.run(
            f"exec {str(cmd_prefix)} '{str(cmd)}'",
            shell=True,
            stdin=subprocess.PIPE,
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
        )

        return proc.returncode, proc.stdout, proc.stderr

    def remote_send_file(self, src, dest, mode):
        priv_key = self.prepare_priv_key()
        cmd_prefix = self.get_ssh_cmd_prefix(
            self.ssh_user, self.ssh_host, self.ssh_port, priv_key
        )

        proc = subprocess.run(
            f"cat {src} | {cmd_prefix} install -m {mode} /dev/stdin {dest}",
            shell=True,
            stdin=subprocess.PIPE,
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
        )

        return proc.returncode, proc.stdout, proc.stderr

    def run_script(self, script, cmd_prefix):
        file_dirname = os.path.abspath(os.path.dirname(__file__))
        script_dir = self.params.get('test_script_dir', default=file_dirname)
        script_dir = script_dir + '/scripts/'
        script_path = script_dir + script.split()[0]
        script_args = ' '.join(script.split()[1:])

        if not os.path.exists(script_path):
            self.log.error(f"Script not found: {script_path}")
            return (2, '', f"Script not found: {script_path}")

        rc, stdout, stderr = self.remote_send_file(
            script_path, './ci.sh', '755'
        )

        if rc != 0:
            self.log.error("Failed to deploy the script on target")
            return (rc, stdout, stderr)

        time.sleep(1)

        proc = subprocess.run(
            f"{cmd_prefix} ./ci.sh {script_args}",
            shell=True,
            stdin=subprocess.PIPE,
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
        )

        return (proc.returncode, proc.stdout, proc.stderr)

    def wait_connection(self, cmd_prefix, timeout):
        self.log.info("Waiting for SSH server ready...")

        rc = None
        stdout = ''
        stderr = ''

        goodcnt = 0
        # Use 3 good SSH ping attempts to consider SSH connection is stable
        while time.time() < timeout and goodcnt < 3:
            goodcnt += 1

            rc, stdout, stderr = self.exec_cmd('/bin/true', cmd_prefix)
            time.sleep(1)

            if rc != 0:
                goodcnt = 0

            time_left = timeout - time.time()
            self.log.info("SSH ping result: %d, left: %.fs" % (rc, time_left))

        return rc, stdout, stderr

    def prepare_priv_key(self):
        # Copy private key to build directory (that is writable)
        priv_key = '%s/ci_priv_key' % self.build_dir
        if not os.path.exists(priv_key):
            key = os.path.join(os.path.dirname(__file__), 'keys/ssh/id_rsa')
            shutil.copy(key, priv_key)
        os.chmod(priv_key, 0o400)

        return priv_key

    def remote_run(self, cmd=None, script=None, timeout=0):
        if cmd:
            self.log.info(f"Remote command is `{cmd}`")
        if script:
            self.log.info(f"Remote script is `{script}`")

        priv_key = self.prepare_priv_key()
        cmd_prefix = self.get_ssh_cmd_prefix(
            self.ssh_user, self.ssh_host, self.ssh_port, priv_key
        )

        rc = None
        stdout = ''
        stderr = ''

        if timeout != 0:
            rc, stdout, stderr = self.wait_connection(cmd_prefix, timeout)

        if rc == 0 or timeout == 0:
            if cmd is not None:
                rc, stdout, stderr = self.exec_cmd(cmd, cmd_prefix)
                self.log.info(f"`{cmd}` returned {str(rc)}")
            elif script is not None:
                rc, stdout, stderr = self.run_script(script, cmd_prefix)
                self.log.info(f"`{script}` returned {str(rc)}")

        return rc, stdout, stderr

    def ssh_start(
        self, user='ci', host='localhost', port=22, cmd=None, script=None
    ):
        self.log.info("===================================================")
        self.log.info(f"Running Isar SSH test for `{user}@{host}:{port}`")
        self.log.info(f"Isar build folder is: {self.build_dir}")
        self.log.info("===================================================")

        self.check_init()

        self.ssh_user = user
        self.ssh_host = host
        self.ssh_port = port

        priv_key = self.prepare_priv_key()
        cmd_prefix = self.get_ssh_cmd_prefix(
            self.ssh_user, self.ssh_host, self.ssh_port, priv_key
        )
        self.log.info(f"Connect command:\n{cmd_prefix}")

        if cmd is not None or script is not None:
            rc, stdout, stderr = self.remote_run(cmd, script)

            if rc != 0:
                self.whiteboard += f'stdout:\n{stdout}\n\nstderr:\n{stderr}\n'
                self.fail(f"Failed with rc={rc}")

            return stdout, stderr

        self.fail("No command to run specified")

    def vm_turn_on(
        self,
        arch='amd64',
        distro='buster',
        image='isar-image-base',
        enforce_pcbios=False,
    ):
        logdir = '%s/vm_start' % self.build_dir
        if not os.path.exists(logdir):
            os.mkdir(logdir)
        prefix = f"{time.strftime('%Y%m%d-%H%M%S')}-vm_start_{distro}_{arch}_"
        fd, boot_log = tempfile.mkstemp(
            suffix='_log.txt', prefix=prefix, dir=logdir, text=True
        )
        os.chmod(boot_log, 0o644)
        latest_link = '%s/vm_start_%s_%s_latest.txt' % (logdir, distro, arch)
        if os.path.exists(latest_link):
            os.unlink(latest_link)
        os.symlink(os.path.basename(boot_log), latest_link)

        cmdline = start_vm.format_qemu_cmdline(
            arch, self.build_dir, distro, image, boot_log, None, enforce_pcbios
        )
        cmdline.insert(1, '-nographic')

        need_sb_cleanup = start_vm.sb_copy_vars(cmdline)

        self.log.info(f"QEMU boot line:\n{' '.join(cmdline)}")
        self.log.info(f"QEMU boot log:\n{boot_log}")

        p1 = subprocess.Popen(
            f"exec {' '.join(cmdline)}",
            shell=True,
            stdin=subprocess.PIPE,
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
            universal_newlines=True,
        )
        self.log.info("Started VM with pid %s" % (p1.pid))

        return p1, cmdline, boot_log, need_sb_cleanup

    def vm_wait_boot(self, p1, timeout):
        login_prompt = b' login:'

        poller = select.poll()
        poller.register(p1.stdout, select.POLLIN)
        poller.register(p1.stderr, select.POLLIN)

        # Databuf of size enough to keep two data chunks + checked string
        databuf = bytearray(b'')
        databuf_size = 1024 * 2 + len(login_prompt)

        while time.time() < timeout:
            events = poller.poll(1000 * (timeout - time.time()))
            for fd, event in events:
                if event != select.POLLIN:
                    continue
                if fd == p1.stdout.fileno():
                    data = os.read(fd, 1024)
                    shift = max(0, len(data) + len(databuf) - databuf_size)
                    databuf = databuf[shift:] + bytearray(data)
                    if login_prompt in databuf:
                        self.log.info("Got login prompt")
                        return 0
                if fd == p1.stderr.fileno():
                    app_log.error(p1.stderr.readline().rstrip())
            if p1.poll() is not None:
                break

        self.log.error("Didn't get login prompt")
        return 1

    def vm_parse_output(self, boot_log, multiconfig, skip_modulecheck):
        # the printk of recipes-kernel/example-module
        module_output = b'Just an example'
        resize_output = None
        # systemd service ordering cycle
        ordering_cycle = b'Found ordering cycle'
        image_fstypes, wks_file, bbdistro = CIUtils.getVars(
            'IMAGE_FSTYPES', 'WKS_FILE', 'DISTRO', target=multiconfig
        )

        # only the first type will be tested in start_vm
        if image_fstypes.split()[0] == 'wic':
            if wks_file:
                # ubuntu is less verbose so we do not see the message
                # /etc/sysctl.d/10-console-messages.conf
                if bbdistro and 'ubuntu' not in bbdistro:
                    if 'sdimage-efi-sd' in wks_file:
                        # output we see when expand-on-first-boot runs on ext4
                        resize_output = b'resized filesystem to'
                    if 'sdimage-efi-btrfs' in wks_file:
                        resize_output = b': resize device '
        rc = 0
        if os.path.exists(boot_log) and os.path.getsize(boot_log) > 0:
            with open(boot_log, 'rb') as f1:
                data = f1.read()
                if module_output in data or skip_modulecheck:
                    if resize_output and resize_output not in data:
                        rc = 1
                        self.log.error("No resize output while expected")
                else:
                    rc = 2
                    self.log.error("No example module output while expected")
                if ordering_cycle in data:
                    rc = 3
                    self.log.error("Systemd services ordering cycle detected")
        return rc

    def vm_dump_dict(self, vm):
        f = open(self.vm_dict_file, 'wb')
        pickle.dump(self.vm_dict, f)
        f.close()

    def vm_turn_off(self, vm):
        pid = self.vm_dict[vm][0]
        os.kill(pid, signal.SIGKILL)

        if self.vm_dict[vm][3]:
            start_vm.sb_cleanup()

        del self.vm_dict[vm]
        self.vm_dump_dict(vm)

        self.log.info("Stopped VM with pid %s" % (pid))

    def vm_start(
        self,
        arch='amd64',
        distro='buster',
        enforce_pcbios=False,
        skip_modulecheck=False,
        image='isar-image-base',
        cmd=None,
        script=None,
        keep=False,
    ):
        time_to_wait = self.params.get('time_to_wait', default=DEF_VM_TO_SEC)

        self.log.info("===================================================")
        self.log.info(f"Running Isar VM boot test for ({distro}-{arch})")
        self.log.info(f"Remote command is {str(cmd)}")
        self.log.info(f"Remote script is {str(script)}")
        self.log.info(f"Isar build folder is: {self.build_dir}")
        self.log.info("===================================================")

        self.check_init()

        timeout = time.time() + int(time_to_wait)

        vm = "%s_%s_%s_%d" % (arch, distro, image, enforce_pcbios)

        p1 = None
        pid = None
        cmdline = ''
        boot_log = ''

        run_qemu = True

        stdout = ''
        stderr = ''

        if vm in self.vm_dict:
            pid, cmdline, boot_log, need_sb_cleanup = self.vm_dict[vm]

            # Check that corresponding process exists
            proc = subprocess.run(
                f"ps -o cmd= {pid}",
                shell=True,
                text=True,
                stdout=subprocess.PIPE,
                stderr=subprocess.STDOUT,
            )
            if cmdline[0] in proc.stdout:
                self.log.info(
                    f"Found '{cmdline[0]}' process with pid '{pid}', use it"
                )
                run_qemu = False

        if run_qemu:
            self.log.info(
                f"No qemu-system process for `{vm}` found, run new VM"
            )

            p1, cmdline, boot_log, need_sb_cleanup = self.vm_turn_on(
                arch, distro, image, enforce_pcbios
            )
            self.vm_dict[vm] = p1.pid, cmdline, boot_log, need_sb_cleanup
            self.vm_dump_dict(vm)

            rc = self.vm_wait_boot(p1, timeout)
            if rc != 0:
                self.vm_turn_off(vm)
                self.fail("Failed to boot qemu machine")

        if cmd is not None or script is not None:
            self.ssh_user = 'ci'
            self.ssh_host = 'localhost'
            self.ssh_port = 22
            for arg in cmdline:
                match = re.match(r".*hostfwd=tcp::(\d*).*", arg)
                if match:
                    self.ssh_port = match.group(1)
                    break

            priv_key = self.prepare_priv_key()
            cmd_prefix = self.get_ssh_cmd_prefix(
                self.ssh_user, self.ssh_host, self.ssh_port, priv_key
            )
            self.log.info(f"Connect command:\n{cmd_prefix}")

            rc, stdout, stderr = self.remote_run(cmd, script, timeout)

            standard_output = stdout.decode('utf-8') if isinstance(stdout, bytes) else stdout
            standard_error = stderr.decode('utf-8') if isinstance(stderr, bytes) else stderr
            self.log.info("standard output log:\n" + standard_output)
            self.log.info("standard error log:\n" + standard_error)

            if rc != 0:
                if not keep:
                    self.vm_turn_off(vm)
                self.whiteboard += f'stdout:\n{stdout}\n\nstderr:\n{stderr}\n'
                self.fail("Failed to run test over ssh")
        else:
            multiconfig = 'mc:qemu' + arch + '-' + distro + ':' + image
            rc = self.vm_parse_output(boot_log, multiconfig, skip_modulecheck)
            if rc != 0:
                if not keep:
                    self.vm_turn_off(vm)
                self.fail("Failed to parse output")

        if not keep:
            self.vm_turn_off(vm)

        return stdout, stderr
