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

class ReproTest(CIBaseTest):

    """
    Test cached base repository

    :avocado: tags=repro,full
    """
    def test_repro_signed(self):
        targets = [
            'mc:de0-nano-soc-bullseye:isar-image-base',
            'mc:qemuarm64-bullseye:isar-image-base'
                  ]

        self.perform_repro_test(targets, 1)

    def test_repro_unsigned(self):
        targets = [
            'mc:qemuamd64-bullseye:isar-image-base',
            'mc:qemuarm-bullseye:isar-image-base'
                  ]

        self.perform_repro_test(targets, 0)

class CcacheTest(CIBaseTest):

    """
    Test rebuild speed improve with ccache

    :avocado: tags=ccache
    """
    def test_ccache_rebuild(self):
        targets = ['mc:de0-nano-soc-bullseye:isar-image-base']
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
            'mc:qemuarm64-bullseye:isar-image-base',
            'mc:de0-nano-soc-bullseye:isar-image-base',
            'mc:stm32mp15x-buster:isar-image-base',
            'mc:rpi-stretch:isar-image-base'
                  ]

        self.perform_build_test(targets, 1, None)

    def test_cross_ubuntu(self):
        targets = [
            'mc:qemuarm64-focal:isar-image-base'
                  ]

        try:
            self.perform_build_test(targets, 1, None)
        except:
            self.cancel('KFAIL')

    def test_cross_bookworm(self):
        targets = [
            'mc:qemuarm-bookworm:isar-image-base'
                  ]

        try:
            self.perform_build_test(targets, 1, None)
        except:
            self.cancel('KFAIL')

class SdkTest(CIBaseTest):

    """
    In addition test SDK creation

    :avocado: tags=sdk,fast,full
    """
    def test_sdk(self):
        targets = ['mc:qemuarm-bullseye:isar-image-base']

        self.perform_build_test(targets, 1, 'do_populate_sdk')

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
            'mc:qemui386-stretch:isar-image-base',
            'mc:qemui386-buster:isar-image-base',
            'mc:qemui386-bullseye:isar-image-base',
            'mc:qemuamd64-buster:isar-image-base',
            'mc:qemuamd64-bullseye:isar-image-base',
            'mc:qemuamd64-bullseye-tgz:isar-image-base',
            'mc:qemuamd64-bullseye-cpiogz:isar-image-base',
            'mc:qemuamd64-bullseye:isar-initramfs',
            'mc:qemumipsel-buster:isar-image-base',
            'mc:qemumipsel-bullseye:isar-image-base',
            'mc:qemuriscv64-sid-ports:isar-image-base',
            'mc:sifive-fu540-sid-ports:isar-image-base',
            'mc:nand-ubi-demo-bullseye:isar-image-ubi',
            'mc:rpi-stretch:isar-image-base',
            'mc:hikey-bullseye:isar-image-base',
            'mc:virtualbox-bullseye:isar-image-base',
            'mc:bananapi-bullseye:isar-image-base',
            'mc:nanopi-neo-bullseye:isar-image-base',
            'mc:stm32mp15x-bullseye:isar-image-base',
            'mc:qemuamd64-focal:isar-image-base'
                  ]

        # Cleanup after cross build
        self.deletetmp(self.params.get('build_dir',
                       default=os.path.dirname(__file__) + '/../../build'))

        self.perform_build_test(targets, 0, None)

    def test_nocross_bookworm(self):
        targets = [
            'mc:qemuamd64-bookworm:isar-image-base',
            'mc:qemuarm-bookworm:isar-image-base',
            'mc:qemui386-bookworm:isar-image-base',
            'mc:qemumipsel-bookworm:isar-image-base',
            'mc:hikey-bookworm:isar-image-base'
                  ]

        try:
            self.perform_build_test(targets, 0, None)
        except:
            self.cancel('KFAIL')

class RebuildTest(CIBaseTest):

    """
    Test image rebuild

    :avocado: tags=rebuild,fast,full
    """
    def test_rebuild(self):
        is_cross_build = int(self.params.get('cross', default=0))

        layerdir_core = self.getlayerdir('core')

        dpkgbase_file = layerdir_core + '/classes/dpkg-base.bbclass'

        self.backupfile(dpkgbase_file)
        with open(dpkgbase_file, 'a') as file:
            file.write('do_fetch_append() {\n\n}')

        try:
            self.perform_build_test('mc:qemuamd64-bullseye:isar-image-base',
                                    is_cross_build, None)
        finally:
            self.restorefile(dpkgbase_file)

class ContainerImageTest(CIBaseTest):

    """
    Test containerized images creation

    :avocado: tags=containerbuild,fast,full,container
    """
    @skipUnless(UMOCI_AVAILABLE and SKOPEO_AVAILABLE, 'umoci/skopeo not found')
    def test_nocross(self):
        targets = [
            'mc:container-amd64-stretch:isar-image-base',
            'mc:container-amd64-buster:isar-image-base',
            'mc:container-amd64-bullseye:isar-image-base',
            'mc:container-amd64-bookworm:isar-image-base'
                  ]

        self.perform_container_test(targets, None)

class ContainerSdkTest(CIBaseTest):

    """
    Test SDK container image creation

    :avocado: tags=containersdk,fast,full,container
    """
    @skipUnless(UMOCI_AVAILABLE and SKOPEO_AVAILABLE, 'umoci/skopeo not found')
    def test_container_sdk(self):
        targets = ['mc:container-amd64-stretch:isar-image-base']

        self.perform_container_test(targets, 'do_populate_sdk')
