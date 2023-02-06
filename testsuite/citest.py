#!/usr/bin/env python3

import os

from avocado import skipUnless
from avocado.utils import path
from cibase import CIBaseTest

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

    :avocado: tags=dev,fast,full
    """
    def test_dev(self):
        targets = [
            'mc:qemuamd64-bullseye:isar-image-base',
            'mc:qemuarm-bullseye:isar-image-base',
            'mc:qemuarm-bullseye:isar-image-base:do_populate_sdk',
            'mc:qemuarm64-bullseye:isar-image-base'
                  ]

        self.init()
        self.perform_build_test(targets, cross=True, image_install="example-raw")

    def test_dev_apps(self):
        targets = [
            'mc:qemuamd64-bullseye:isar-image-base',
            'mc:qemuarm64-bullseye:isar-image-base'
                  ]

        self.init()
        self.perform_build_test(targets)

    def test_dev_rebuild(self):
        self.init()
        layerdir_core = self.getlayerdir('core')

        dpkgbase_file = layerdir_core + '/classes/dpkg-base.bbclass'

        self.backupfile(dpkgbase_file)
        with open(dpkgbase_file, 'a') as file:
            file.write('do_fetch:append() {\n\n}')

        try:
            self.perform_build_test('mc:qemuamd64-bullseye:isar-image-base')
        finally:
            self.restorefile(dpkgbase_file)

    def test_dev_run_amd64_bullseye(self):
        self.init()
        self.vm_start('amd64', 'bullseye')

    def test_dev_run_arm64_bullseye(self):
        self.init()
        self.vm_start('arm64', 'bullseye')

    def test_dev_run_arm_bullseye(self):
        self.init()
        self.vm_start('arm', 'bullseye')

class ReproTest(CIBaseTest):

    """
    Test cached base repository

    :avocado: tags=repro,full
    """
    def test_repro_signed(self):
        targets = [
            'mc:rpi-arm-v7-bullseye:isar-image-base',
            'mc:qemuarm64-bullseye:isar-image-base'
                  ]

        self.init()
        try:
            self.perform_repro_test(targets, signed=True, cross=True)
        finally:
            self.move_in_build_dir('tmp', 'tmp_repro_signed')

    def test_repro_unsigned(self):
        targets = [
            'mc:qemuamd64-bullseye:isar-image-base',
            'mc:qemuarm-bullseye:isar-image-base'
                  ]

        self.init()
        try:
            self.perform_repro_test(targets)
        finally:
            self.move_in_build_dir('tmp', 'tmp_repro_unsigned')

class CcacheTest(CIBaseTest):

    """
    Test rebuild speed improve with ccache

    :avocado: tags=ccache,fast,full
    """
    def test_ccache_rebuild(self):
        targets = ['mc:qemuamd64-bullseye:hello-isar']
        self.init()
        self.perform_ccache_test(targets)

class CrossTest(CIBaseTest):

    """
    Start cross build for the defined set of configurations

    :avocado: tags=cross,fast,full
    """
    def test_cross(self):
        targets = [
            'mc:qemuarm-buster:isar-image-base',
            'mc:qemuarm-bullseye:isar-image-base',
            'mc:de0-nano-soc-bullseye:isar-image-base',
            'mc:stm32mp15x-buster:isar-image-base'
                  ]

        self.init()
        self.perform_build_test(targets, cross=True, debsrc_cache=True)

    def test_cross_rpi(self):
        targets = [
            'mc:rpi-arm-v7-bullseye:isar-image-base'
                  ]

        self.init()
        try:
            self.perform_build_test(targets, cross=True, debsrc_cache=True)
        except:
            self.cancel('KFAIL')

    def test_cross_ubuntu(self):
        targets = [
            'mc:qemuarm64-focal:isar-image-base'
                  ]

        self.init()
        try:
            self.perform_build_test(targets, cross=True)
        except:
            self.cancel('KFAIL')

    def test_cross_bookworm(self):
        targets = [
            'mc:qemuarm-bookworm:isar-image-base',
            'mc:qemuarm64-bookworm:isar-image-base'
                  ]

        self.init()
        try:
            self.perform_build_test(targets, cross=True)
        except:
            self.cancel('KFAIL')

class WicTest(CIBaseTest):

    """
    Test creation of wic images

    :avocado: tags=wic,full
    """
    def test_wic_nodeploy_partitions(self):
        targets = ['mc:qemuarm64-bookworm:isar-image-base']

        self.init()
        self.delete_from_build_dir('tmp')
        self.perform_wic_partition_test(targets,
            wic_deploy_parts=False, debsrc_cache=True, compat_arch=False)

    def test_wic_deploy_partitions(self):
        targets = ['mc:qemuarm64-bookworm:isar-image-base']

        self.init()
        # reuse artifacts
        self.perform_wic_partition_test(targets,
            wic_deploy_parts=True, debsrc_cache=True, compat_arch=False)

class NoCrossTest(CIBaseTest):

    """
    Start non-cross build for the defined set of configurations

    :avocado: tags=nocross,full
    """
    def test_nocross(self):
        targets = [
            'mc:qemuarm-buster:isar-image-base',
            'mc:qemuarm-bullseye:isar-image-base',
            'mc:qemuarm64-bullseye:isar-image-base',
            'mc:qemui386-buster:isar-image-base',
            'mc:qemui386-bullseye:isar-image-base',
            'mc:qemuamd64-buster:isar-image-base',
            'mc:qemuamd64-bullseye:isar-initramfs',
            'mc:qemumipsel-buster:isar-image-base',
            'mc:qemumipsel-bullseye:isar-image-base',
            'mc:imx6-sabrelite-bullseye:isar-image-base',
            'mc:phyboard-mira-bullseye:isar-image-base',
            'mc:hikey-bullseye:isar-image-base',
            'mc:virtualbox-bullseye:isar-image-base',
            'mc:bananapi-bullseye:isar-image-base',
            'mc:nanopi-neo-bullseye:isar-image-base',
            'mc:stm32mp15x-bullseye:isar-image-base',
            'mc:qemuamd64-focal:isar-image-base'
                  ]

        self.init()
        # Cleanup after cross build
        self.delete_from_build_dir('tmp')
        self.perform_build_test(targets, cross=False, debsrc_cache=True)

    def test_nocross_rpi(self):
        targets = [
            'mc:rpi-arm-bullseye:isar-image-base',
            'mc:rpi-arm-v7-bullseye:isar-image-base',
            'mc:rpi-arm-v7l-bullseye:isar-image-base',
            'mc:rpi-arm64-v8-bullseye:isar-image-base'
                  ]

        self.init()
        try:
            self.perform_build_test(targets, cross=False, debsrc_cache=True)
        except:
            self.cancel('KFAIL')

    def test_nocross_bookworm(self):
        targets = [
            'mc:qemuamd64-bookworm:isar-image-base',
            'mc:qemuarm-bookworm:isar-image-base',
            'mc:qemui386-bookworm:isar-image-base',
            'mc:qemumipsel-bookworm:isar-image-base',
            'mc:hikey-bookworm:isar-image-base'
                  ]

        self.init()
        try:
            self.perform_build_test(targets, cross=False)
        except:
            self.cancel('KFAIL')

    def test_nocross_sidports(self):
        targets = [
            'mc:qemuriscv64-sid-ports:isar-image-base',
            'mc:sifive-fu540-sid-ports:isar-image-base'
                  ]

        self.init()
        try:
            self.perform_build_test(targets, cross=False)
        except:
            self.cancel('KFAIL')

class ContainerImageTest(CIBaseTest):

    """
    Test containerized images creation

    :avocado: tags=containerbuild,fast,full,container
    """
    @skipUnless(UMOCI_AVAILABLE and SKOPEO_AVAILABLE, 'umoci/skopeo not found')
    def test_container_image(self):
        targets = [
            'mc:container-amd64-buster:isar-image-base',
            'mc:container-amd64-bullseye:isar-image-base',
            'mc:container-amd64-bookworm:isar-image-base'
                  ]

        self.init()
        self.perform_build_test(targets, container=True)

class ContainerSdkTest(CIBaseTest):

    """
    Test SDK container image creation

    :avocado: tags=containersdk,fast,full,container
    """
    @skipUnless(UMOCI_AVAILABLE and SKOPEO_AVAILABLE, 'umoci/skopeo not found')
    def test_container_sdk(self):
        targets = ['mc:container-amd64-bullseye:isar-image-base']

        self.init()
        self.perform_build_test(targets, bitbake_cmd='do_populate_sdk', container=True)

class SstateTest(CIBaseTest):

    """
    Test builds with artifacts taken from sstate cache

    :avocado: tags=sstate,fast,full
    """
    def test_sstate(self):
        image_target = 'mc:qemuamd64-bullseye:isar-image-base'
        package_target = 'mc:qemuamd64-bullseye:hello'

        self.init('build-sstate')
        self.perform_sstate_test(image_target, package_target)

class VmBootTestFast(CIBaseTest):

    """
    Test QEMU image start (fast)

    :avocado: tags=startvm,fast
    """
    def test_arm_bullseye(self):
        self.init()
        self.vm_start('arm','bullseye')

    def test_arm_buster(self):
        self.init()
        self.vm_start('arm','buster')

    def test_arm_bookworm(self):
        self.init()
        self.vm_start('arm','bookworm')

class VmBootTestFull(CIBaseTest):

    """
    Test QEMU image start (full)

    :avocado: tags=startvm,full
    """
    def test_arm_bullseye(self):
        self.init()
        self.vm_start('arm','bullseye')

    def test_arm_buster(self):
        self.init()
        self.vm_start('arm','buster')

    def test_arm64_bullseye(self):
        self.init()
        self.vm_start('arm64','bullseye')

    def test_i386_buster(self):
        self.init()
        self.vm_start('i386','buster')

    def test_amd64_buster(self):
        self.init()
        # test efi boot
        self.vm_start('amd64','buster')
        # test pcbios boot
        self.vm_start('amd64', 'buster', True)

    def test_amd64_focal(self):
        self.init()
        self.vm_start('amd64','focal')

    def test_amd64_bookworm(self):
        self.init()
        self.vm_start('amd64','bookworm')

    def test_arm_bookworm(self):
        self.init()
        self.vm_start('arm','bookworm')

    def test_i386_bookworm(self):
        self.init()
        self.vm_start('i386','bookworm')

    def test_mipsel_bookworm(self):
        self.init()
        self.vm_start('mipsel','bookworm')
