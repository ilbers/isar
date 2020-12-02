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

    :avocado: tags=repro,fast,full
    """
    def test_repro_signed(self):
        targets = [
            'mc:de0-nano-soc-buster:isar-image-base',
            'mc:qemuarm64-stretch:isar-image-base'
                  ]

        self.perform_repro_test(targets, 1)

    def test_repro_unsigned(self):
        targets = [
            'mc:qemuamd64-stretch:isar-image-base',
            'mc:qemuarm-stretch:isar-image-base'
                  ]

        self.perform_repro_test(targets, 0)

class CrossTest(CIBaseTest):

    """
    Start cross build for the defined set of configurations

    :avocado: tags=cross,fast,full
    """
    def test_cross(self):
        targets = [
            'mc:qemuarm-stretch:isar-image-base',
            'mc:qemuarm-buster:isar-image-base',
            'mc:qemuarm64-stretch:isar-image-base',
            'mc:qemuamd64-stretch:isar-image-base',
            'mc:de0-nano-soc-buster:isar-image-base',
            'mc:stm32mp15x-buster:isar-image-base',
            'mc:rpi-stretch:isar-image-base',
            'mc:qemuarm64-focal:isar-image-base'
                  ]

        self.perform_build_test(targets, 1, None)

    def test_cross_bullseye(self):
        targets = [
            'mc:qemuarm-bullseye:isar-image-base'
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
        targets = ['mc:qemuarm-stretch:isar-image-base']

        self.perform_build_test(targets, 1, 'do_populate_sdk')

class NoCrossTest(CIBaseTest):

    """
    Start non-cross build for the defined set of configurations

    :avocado: tags=nocross,full
    """
    def test_nocross(self):
        targets = [
            'mc:qemuarm-stretch:isar-image-base',
            'mc:qemuarm-buster:isar-image-base',
            'mc:qemuarm64-stretch:isar-image-base',
            'mc:qemui386-stretch:isar-image-base',
            'mc:qemui386-buster:isar-image-base',
            'mc:qemuamd64-stretch:isar-image-base',
            'mc:qemuamd64-buster:isar-image-base',
            'mc:qemuamd64-buster-tgz:isar-image-base',
            'mc:qemuamd64-buster-cpiogz:isar-image-base',
            'mc:qemuamd64-buster:isar-initramfs',
            'mc:qemumipsel-stretch:isar-image-base',
            'mc:qemumipsel-buster:isar-image-base',
            'mc:nand-ubi-demo-buster:isar-image-ubi',
            'mc:rpi-stretch:isar-image-base',
            'mc:qemuamd64-focal:isar-image-base',
            'mc:virtualbox-ova-buster:isar-image-base'
                  ]

        # Cleanup after cross build
        self.deletetmp(self.params.get('build_dir',
                       default=os.path.dirname(__file__) + '/../../build'))

        self.perform_build_test(targets, 0, None)

    def test_nocross_bullseye(self):
        targets = [
            'mc:qemuamd64-bullseye:isar-image-base',
            'mc:qemuarm-bullseye:isar-image-base',
            'mc:qemui386-bullseye:isar-image-base',
            'mc:qemumipsel-bullseye:isar-image-base'
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
            self.perform_build_test('mc:qemuamd64-stretch:isar-image-base',
                                    is_cross_build, None)
        finally:
            self.restorefile(dpkgbase_file)

class WicTest(CIBaseTest):

    """
    Test wic --exclude-path

    :avocado: tags=wic,fast,full
    """
    def test_wic_exclude(self):
        # TODO: remove hardcoded filenames
        wks_path = '/scripts/lib/wic/canned-wks/sdimage-efi.wks'
        wic_path = '/tmp/deploy/images/qemuamd64/isar-image-base-debian-stretch-qemuamd64.wic.img'

        self.perform_wic_test('mc:qemuamd64-stretch:isar-image-base',
                              wks_path, wic_path)

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
            'mc:container-amd64-bullseye:isar-image-base'
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
