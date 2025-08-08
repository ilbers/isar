#!/usr/bin/env python3
#
# This software is a part of ISAR.
# Copyright (C) 2022-2025 ilbers GmbH
# Copyright (C) 2022-2025 Siemens AG
#
# SPDX-License-Identifier: MIT

from avocado import skipUnless
from avocado.core import exceptions
from avocado.utils import path
from cibase import CIBaseTest
from utils import CIUtils

UMOCI_AVAILABLE = True
SKOPEO_AVAILABLE = True
try:
    path.find_command('umoci')
except path.CmdNotFoundError:
    UMOCI_AVAILABLE = False
try:
    path.find_command('skopeo')
except path.CmdNotFoundError:
    SKOPEO_AVAILABLE = False


class DevTest(CIBaseTest):

    """
    Developer's test

    :avocado: tags=dev,fast
    """

    def test_dev(self):
        targets = [
            'mc:qemuamd64-bookworm:isar-image-ci',
            'mc:qemuarm-bookworm:isar-image-base',
            'mc:qemuarm-bookworm:isar-image-base:do_populate_sdk',
            'mc:qemuarm64-bookworm:isar-image-base',
        ]

        self.init()
        self.perform_build_test(targets, image_install='example-raw')

    def test_dev_apps(self):
        targets = [
            'mc:qemuamd64-bookworm:isar-image-ci',
            'mc:qemuarm64-bookworm:isar-image-base',
        ]

        self.init()
        self.perform_build_test(targets)

    def test_dev_rebuild(self):
        self.init()
        layerdir_core = CIUtils.getVars('LAYERDIR_core')

        dpkgbase_file = layerdir_core + '/classes/dpkg-base.bbclass'

        self.backupfile(dpkgbase_file)
        with open(dpkgbase_file, 'a') as file:
            file.write('do_fetch:append() {\n\n}')

        try:
            self.perform_build_test('mc:qemuamd64-bookworm:isar-image-ci')
        finally:
            self.restorefile(dpkgbase_file)

    def test_dev_run_amd64_bookworm(self):
        self.init()
        self.vm_start('amd64', 'bookworm', image='isar-image-ci')

    def test_dev_run_arm64_bookworm(self):
        self.init()
        self.vm_start('arm64', 'bookworm')

    def test_dev_run_arm_bookworm(self):
        self.init()
        self.vm_start('arm', 'bookworm', skip_modulecheck=True)


class ReproTest(CIBaseTest):

    """
    Test cached base repository

    :avocado: tags=repro,full
    """

    def test_repro_signed(self):
        targets = [
            'mc:rpi-arm-v7-bookworm:isar-image-base',
            'mc:rpi-arm64-v8-bookworm:isar-image-base',
            'mc:qemuarm64-bookworm:isar-image-base',
        ]

        self.init()
        try:
            self.perform_repro_test(targets, signed=True)
        finally:
            self.move_in_build_dir('tmp', 'tmp_repro_signed')

    def test_repro_unsigned(self):
        targets = [
            'mc:qemuamd64-bookworm:isar-image-base',
            'mc:qemuarm-bookworm:isar-image-base',
        ]

        self.init()
        try:
            self.perform_repro_test(targets, cross=False)
        finally:
            self.move_in_build_dir('tmp', 'tmp_repro_unsigned')


class CcacheTest(CIBaseTest):

    """
    Test rebuild speed improve with ccache

    :avocado: tags=ccache,full
    """

    def test_ccache_rebuild(self):
        targets = ['mc:qemuamd64-bullseye:hello-isar']
        self.init()
        self.perform_ccache_test(targets)


class InstallerTest(CIBaseTest):

    """
    Installer test

    :avocado: tags=installer,full
    """

    def test_installer_build(self):
        self.init()
        self.perform_build_test("mc:isar-installer:isar-image-installer",
                                installer_image="isar-image-ci",
                                installer_machine="qemuamd64",
                                installer_distro="debian-bookworm",
                                installer_device="/dev/sda")

    def test_installer_run(self):
        self.init()
        self.vm_start('amd64', 'bookworm', image='isar-image-installer',
                      keep=True)

    def test_installer_root_partition(self):
        self.init()
        self.vm_start('amd64', 'bookworm', image='isar-image-installer',
            cmd='findmnt -n -o SOURCE / | grep -q sda2')


class CrossTest(CIBaseTest):

    """
    Start cross build for the defined set of configurations

    :avocado: tags=cross,fast
    """

    def test_cross(self):
        targets = [
            'mc:qemuarm-buster:isar-image-ci',
            'mc:qemuarm-bullseye:isar-image-ci',
            'mc:de0-nano-soc-bullseye:isar-image-base',
            'mc:stm32mp15x-bullseye:isar-image-base',
            'mc:qemuarm-bookworm:isar-image-ci',
            'mc:qemuarm64-focal:isar-image-base',
            'mc:nanopi-neo-efi-bookworm:isar-image-base',
            'mc:phyboard-mira-bookworm:isar-image-base',
        ]

        self.init()
        self.perform_build_test(targets)

    def test_cross_debsrc(self):
        targets = [
            'mc:qemuarm64-bookworm:isar-image-ci',
        ]

        self.init()
        self.perform_build_test(targets, debsrc_cache=True)

    def test_cross_kselftest(self):
        targets = [
            'mc:qemuarm-buster:kselftest',
            'mc:qemuarm-bullseye:kselftest',
            'mc:de0-nano-soc-bullseye:kselftest',
            'mc:stm32mp15x-bullseye:kselftest',
            'mc:qemuarm-bookworm:kselftest',
            'mc:qemuarm64-bookworm:kselftest',
            'mc:qemuarm64-focal:kselftest',
            'mc:nanopi-neo-efi-bookworm:kselftest',
            'mc:phyboard-mira-bookworm:kselftest',
        ]

        self.init()
        self.perform_build_test(targets)

    def test_cross_rpi(self):
        targets = [
            'mc:rpi-arm-v7-bullseye:isar-image-base',
            'mc:rpi-arm64-v8-efi-bookworm:isar-image-base',
        ]

        self.init()
        self.perform_build_test(targets)


class KernelTests(CIBaseTest):
    """
    Tests associated with kernel builds and development.
    :avocado: tags=kernel,full
    """

    def test_per_kernel(self):
        """Test per-kernel recipe variants for external kernel modules."""

        targets = ['mc:qemuarm64-bookworm:isar-image-ci']
        kernel_names = self.params.get('kernel_names', default='mainline')
        kernel_names = [k.strip() for k in kernel_names.split(',') if k.strip()]
        modules = [f"example-module-{k}" for k in kernel_names]
        modules.append('example-module-${KERNEL_NAME}')
        kernel_names = ' '.join(sorted(kernel_names))
        lines = [
            f"KERNEL_NAMES:append = ' {kernel_names}'",
        ]
        self.init()
        self.perform_build_test(targets, image_install=' '.join(modules), lines=lines)


class WicTest(CIBaseTest):

    """
    Test creation of wic images

    :avocado: tags=wic,full
    """

    def test_wic_nodeploy_partitions(self):
        targets = ['mc:qemuarm64-bookworm:isar-image-ci']

        self.init()
        self.move_in_build_dir('tmp', 'tmp_before_wic')
        self.perform_wic_partition_test(
            targets,
            wic_deploy_parts=False,
            compat_arch=False,
        )

    def test_wic_deploy_partitions(self):
        targets = ['mc:qemuarm64-bookworm:isar-image-ci']

        self.init()
        # reuse artifacts
        self.perform_wic_partition_test(
            targets,
            wic_deploy_parts=True,
            compat_arch=False,
        )


class NoCrossTest(CIBaseTest):

    """
    Start non-cross build for the defined set of configurations

    :avocado: tags=nocross,full
    """

    def test_nocross(self):
        targets = [
            'mc:qemuarm-buster:isar-image-ci',
            'mc:qemuarm-bullseye:isar-image-base',
            'mc:qemuarm64-bullseye:isar-image-base',
            'mc:qemuarm64-bookworm:isar-image-ci',
            'mc:qemui386-buster:isar-image-base',
            'mc:qemui386-bullseye:isar-image-base',
            'mc:qemuamd64-buster:isar-image-ci',
            'mc:qemuamd64-bullseye:isar-initramfs',
            'mc:qemumipsel-bullseye:isar-image-base',
            'mc:imx6-sabrelite-bullseye:isar-image-base',
            'mc:phyboard-mira-bullseye:isar-image-base',
            'mc:hikey-bullseye:isar-image-base',
            'mc:virtualbox-bullseye:isar-image-base',
            'mc:virtualbox-bookworm:isar-image-base',
            'mc:bananapi-bullseye:isar-image-base',
            'mc:bananapi-bookworm:isar-image-base',
            'mc:nanopi-neo-bullseye:isar-image-base',
            'mc:nanopi-neo-bookworm:isar-image-base',
            'mc:qemuamd64-focal:isar-image-ci',
            'mc:qemuamd64-bookworm:isar-image-ci',
            'mc:qemuamd64-iso-bookworm:isar-image-ci',
            'mc:qemui386-bookworm:isar-image-base',
            'mc:qemumipsel-bookworm:isar-image-ci',
            'mc:hikey-bookworm:isar-image-base',
            'mc:beagleplay-bookworm:isar-image-base',
            'mc:qemuarm64-noble:isar-image-base',
            'mc:qemuamd64-noble:isar-image-base',
            'mc:qemuamd64-jammy:isar-image-base',
            'mc:qemuarm64-jammy:isar-image-base',
            'mc:x86-pc-bookworm:isar-image-base',
        ]

        self.init()
        self.perform_build_test(targets, cross=False)

    def test_nocross_debsrc(self):
        targets = [
            'mc:qemuarm-bookworm:isar-image-ci',
            'mc:stm32mp15x-bullseye:isar-image-base',
            'mc:de0-nano-soc-bookworm:isar-image-base',
        ]

        self.init()
        self.perform_build_test(targets, cross=False, debsrc_cache=True)

    def test_nocross_rpi(self):
        targets = [
            'mc:rpi-arm-bullseye:isar-image-base',
            'mc:rpi-arm-v7-bullseye:isar-image-base',
            'mc:rpi-arm-v7l-bullseye:isar-image-base',
            'mc:rpi-arm64-v8-bullseye:isar-image-base',
        ]

        self.init()
        self.perform_build_test(targets, cross=False)

    def test_nocross_rpi_debsrc(self):
        targets = [
            'mc:rpi-arm-bookworm:isar-image-base',
            'mc:rpi-arm-v7l-bookworm:isar-image-base',
        ]

        self.init()
        self.perform_build_test(targets, cross=False, debsrc_cache=True)

    def test_nocross_trixie(self):
        targets = [
            'mc:qemuamd64-trixie:isar-image-base',
            'mc:qemuarm64-trixie:isar-image-base',
            'mc:qemuarm-trixie:isar-image-base',
            'mc:qemuriscv64-trixie:isar-image-base',
            'mc:sifive-fu540-trixie:isar-image-base',
            'mc:starfive-visionfive2-trixie:isar-image-base',
        ]

        self.init()
        try:
            self.perform_build_test(targets, cross=False)
        except exceptions.TestFail:
            self.cancel('KFAIL')

    def test_nocross_sid(self):
        targets = [
            'mc:qemuamd64-sid:isar-image-base',
            'mc:qemuarm64-sid:isar-image-base',
        ]

        self.init()
        try:
            self.perform_build_test(targets, cross=False)
        except exceptions.TestFail:
            self.cancel('KFAIL')


class ContainerImageTest(CIBaseTest):

    """
    Test containerized images creation

    :avocado: tags=containerbuild,full,container
    """

    @skipUnless(UMOCI_AVAILABLE and SKOPEO_AVAILABLE, 'umoci/skopeo not found')
    def test_container_image(self):
        targets = [
            'mc:container-amd64-buster:isar-image-base',
            'mc:container-amd64-bullseye:isar-image-base',
            'mc:container-amd64-bookworm:isar-image-base',
        ]

        self.init()
        self.perform_build_test(targets, container=True)


class ContainerSdkTest(CIBaseTest):

    """
    Test SDK container image creation

    :avocado: tags=containersdk,full,container
    """

    @skipUnless(UMOCI_AVAILABLE and SKOPEO_AVAILABLE, 'umoci/skopeo not found')
    def test_container_sdk(self):
        targets = ['mc:container-amd64-bullseye:isar-image-base']

        self.init()
        self.perform_build_test(
            targets, bitbake_cmd='do_populate_sdk', container=True
        )


class CustomizationsTest(CIBaseTest):
    """
    Test image customizations using the hostname-customizations package.

    :avocado: tags=customizations,single,full
    """

    def test_single_customization(self):
        self.init()
        machine = self.params.get("machine", default="qemuamd64")
        distro = self.params.get("distro", default="bullseye")

        self.perform_build_test("mc:%s-%s:%s" % (machine, distro, "isar-image-ci"), customizations="hostname", image_install="")
        self.vm_start(
            machine.removeprefix('qemu'),
            distro,
            image="isar-image-ci",
            cmd="hostname | grep isar-ci"
        )


class SignatureTest(CIBaseTest):

    """
    Test for signature cachability issues which prevent shared state reuse.

    SstateTest also checks for these, but this test is faster and will check
    more cases.

    :avocado: tags=signatures,sstate
    """

    def test_signature_lint(self):
        verbose = bool(int(self.params.get('verbose', default=0)))
        targets = [
            'mc:qemuamd64-bullseye:isar-image-ci',
            'mc:qemuarm-bullseye:isar-image-base',
            'mc:qemuarm-bullseye:isar-image-base:do_populate_sdk',
            'mc:qemuamd64-focal:isar-image-base',
        ]

        self.init()
        self.perform_signature_lint(targets, verbose=verbose)


class SstateTest(CIBaseTest):

    """
    Test builds with artifacts taken from sstate cache

    :avocado: tags=sstate,full
    """

    def test_sstate_populate(self):
        image_target = 'mc:qemuamd64-bullseye:isar-image-base'

        self.perform_sstate_populate(image_target)

    def test_sstate(self):
        image_target = 'mc:qemuamd64-bullseye:isar-image-base'
        package_target = 'mc:qemuamd64-bullseye:hello'

        self.init('build-sstate')
        self.perform_sstate_test(image_target, package_target)


class SingleTest(CIBaseTest):

    """
    Single test for selected target

    :avocado: tags=single
    """

    def test_single_build(self):
        self.init()
        machine = self.params.get('machine', default='qemuamd64')
        distro = self.params.get('distro', default='bullseye')
        image = self.params.get('image', default='isar-image-base')

        self.perform_build_test('mc:%s-%s:%s' % (machine, distro, image))

    def test_single_run(self):
        self.init()
        machine = self.params.get('machine', default='qemuamd64')
        distro = self.params.get('distro', default='bullseye')

        self.vm_start(machine.removeprefix('qemu'), distro)


class SourceTest(CIBaseTest):

    """
    Source contents test

    :avocado: tags=source,full
    """

    def test_source(self):
        targets = [
            'mc:qemuamd64-bookworm:libhello',
            'mc:qemuarm64-bookworm:libhello',
        ]

        self.init()
        self.perform_source_test(targets)


class VmBootTestFast(CIBaseTest):

    """
    Test QEMU image start (fast)

    :avocado: tags=startvm,fast
    """

    def test_arm_bullseye(self):
        self.init()
        self.vm_start('arm', 'bullseye', image='isar-image-ci', keep=True)

    def test_arm_bullseye_example_module(self):
        self.init()
        self.vm_start(
            'arm',
            'bullseye',
            image='isar-image-ci',
            cmd='lsmod | grep example_module',
            keep=True,
        )

    def test_arm_bullseye_getty_target(self):
        self.init()
        self.vm_start(
            'arm',
            'bullseye',
            image='isar-image-ci',
            script='test_systemd_unit.sh getty.target 10',
        )

    def test_arm_buster(self):
        self.init()
        self.vm_start('arm', 'buster', image='isar-image-ci', keep=True)

    def test_arm_buster_getty_target(self):
        self.init()
        self.vm_start(
            'arm',
            'buster',
            image='isar-image-ci',
            cmd='systemctl is-active getty.target',
            keep=True,
        )

    def test_arm_buster_example_module(self):
        self.init()
        self.vm_start(
            'arm',
            'buster',
            image='isar-image-ci',
            script='test_kernel_module.sh example_module',
        )

    def test_arm_bookworm(self):
        self.init()
        self.vm_start('arm', 'bookworm', image='isar-image-ci', keep=True)

    def test_arm_bookworm_example_module(self):
        self.init()
        self.vm_start(
            'arm',
            'bookworm',
            image='isar-image-ci',
            cmd='lsmod | grep example_module',
            keep=True,
        )

    def test_arm_bookworm_getty_target(self):
        self.init()
        self.vm_start(
            'arm',
            'bookworm',
            image='isar-image-ci',
            script='test_systemd_unit.sh getty.target 10',
        )


class VmBootTestFull(CIBaseTest):

    """
    Test QEMU image start (full)

    :avocado: tags=startvm,full
    """

    def test_arm_bullseye(self):
        self.init()
        self.vm_start('arm', 'bullseye')

    def test_arm_buster(self):
        self.init()
        self.vm_start('arm', 'buster', image='isar-image-ci', keep=True)

    def test_arm_buster_example_module(self):
        self.init()
        self.vm_start(
            'arm',
            'buster',
            image='isar-image-ci',
            cmd='lsmod | grep example_module',
            keep=True,
        )

    def test_arm_buster_getty_target(self):
        self.init()
        self.vm_start(
            'arm',
            'buster',
            image='isar-image-ci',
            script='test_systemd_unit.sh getty.target 10',
        )

    def test_arm_trixie(self):
        self.init()
        try:
            self.vm_start('arm', 'trixie')
        except exceptions.TestFail:
            self.cancel('KFAIL')

    def test_arm64_bookworm(self):
        self.init()
        self.vm_start('arm64', 'bookworm', image='isar-image-ci', keep=True)

    def test_arm64_bookworm_getty_target(self):
        self.init()
        self.vm_start(
            'arm64',
            'bookworm',
            image='isar-image-ci',
            cmd='systemctl is-active getty.target',
            keep=True,
        )

    def test_arm64_bookworm_example_module(self):
        self.init()
        self.vm_start(
            'arm64',
            'bookworm',
            image='isar-image-ci',
            script='test_kernel_module.sh example_module',
            keep=True,
        )

    def test_arm64_trixie(self):
        self.init()
        self.vm_start('arm64', 'trixie')

    def test_i386_buster(self):
        self.init()
        self.vm_start('i386', 'buster')

    def test_amd64_buster(self):
        self.init()
        # test efi boot
        self.vm_start('amd64', 'buster', image='isar-image-ci')
        # test pcbios boot
        self.vm_start('amd64', 'buster', True, image='isar-image-ci')

    def test_amd64_focal(self):
        self.init()
        self.vm_start('amd64', 'focal', image='isar-image-ci', keep=True)

    def test_amd64_focal_example_module(self):
        self.init()
        self.vm_start(
            'amd64',
            'focal',
            image='isar-image-ci',
            cmd='lsmod | grep example_module',
            keep=True,
        )

    def test_amd64_focal_getty_target(self):
        self.init()
        self.vm_start(
            'amd64',
            'focal',
            image='isar-image-ci',
            script='test_systemd_unit.sh getty.target 10',
        )

    def test_amd64_bookworm(self):
        self.init()
        self.vm_start('amd64', 'bookworm', image='isar-image-ci', keep=True)

    def test_arm_bookworm(self):
        self.init()
        self.vm_start('arm', 'bookworm', image='isar-image-ci')

    def test_i386_bookworm(self):
        self.init()
        self.vm_start('i386', 'bookworm')

    def test_mipsel_bookworm(self):
        self.init()
        self.vm_start('mipsel', 'bookworm', image='isar-image-ci', keep=True)

    def test_amd64_trixie(self):
        self.init()
        self.vm_start('amd64', 'trixie')

    def test_mipsel_bookworm_getty_target(self):
        self.init()
        self.vm_start(
            'mipsel',
            'bookworm',
            image='isar-image-ci',
            cmd='systemctl is-active getty.target',
            keep=True,
        )

    def test_mipsel_bookworm_example_module(self):
        self.init()
        self.vm_start(
            'mipsel',
            'bookworm',
            image='isar-image-ci',
            script='test_kernel_module.sh example_module',
        )

    def test_riscv64_trixie(self):
        self.init()
        try:
            self.vm_start('riscv64', 'trixie')
        except exceptions.TestFail:
            self.cancel('KFAIL')

    def test_amd64_bookworm_prebuilt_containers(self):
        self.init()
        self.vm_start('amd64', 'bookworm', image='isar-image-ci',
                      script='test_prebuilt_containers.sh')

    def test_arm64_bookworm_prebuilt_containers(self):
        self.init()
        self.vm_start('arm64', 'bookworm', image='isar-image-ci',
                      script='test_prebuilt_containers.sh')

    def test_amd64_bookworm_iso(self):
        self.init()
        self.vm_start('amd64-iso', 'bookworm', image='isar-image-ci',
                      keep = True
        )

    def test_amd64_bookworm_iso_system_check(self):
        self.init()
        self.vm_start('amd64-iso', 'bookworm', image='isar-image-ci',
                      script='test_system_running.sh 30')


class World(CIBaseTest):

    """
    All targets build test

    :avocado: tags=world
    """

    def test_world(self):
        name = self.params.get('name')
        image = self.params.get('image', default='isar-image-ci')
        targets = []

        if name is None:
            self.init()
            for target in CIUtils.get_targets():
                for image in CIUtils.get_test_images():
                    targets.append(f'mc:{target}:{image}')
        else:
            targets.append(f'mc:{name}:{image}')
            self.init(f'build-{name}')

        self.perform_build_test(
            targets, container=name and name.startswith('container')
        )

    def test_runworld(self):
        name = self.params.get('name')
        image = self.params.get('image', default='isar-image-ci')
        targets = []

        if name is None:
            self.init()
            for target in CIUtils.get_targets():
                for image in CIUtils.get_test_images():
                    targets.append(f'mc:{target}:{image}')
        else:
            targets.append(f'mc:{name}:{image}')
            self.init(f'build-{name}')

        for target in targets:
            t_list = target.split(':', 2)
            if not t_list[1].startswith('qemu'):
                self.cancel(f"{t_list[1]} skipped as non qemu")
            distro = t_list[1].split('-')[-1]
            arch = t_list[1].removeprefix('qemu').removesuffix(f"-{distro}")
            self.vm_start(arch, distro, image=t_list[2])
