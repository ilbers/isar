# This software is a part of Isar.
# Copyright (C) Siemens AG, 2026
#
# SPDX-License-Identifier: MIT

import sys
import tempfile
import unittest
from pathlib import Path

root = Path(__file__).resolve().parents[2]
sys.path.extend([
    str(root / 'bitbake/lib'),
    str(root / 'meta/lib'),
])

import bb.data
from bb.build import exec_func
from bb.parse import handle


data = bb.data.init()
data.setVar('BBPATH', f'{root}/meta:{root}/bitbake')
data.setVar('__bbclasstype', 'recipe')
data.setVar('IMGCLASSES', '')
parsed = handle(str(root / 'meta/classes-recipe/image.bbclass'), data)
data.setVar('IMAGE_TYPEDEP:ova', 'vmdk')
data.setVar('IMAGE_TYPEDEP:vmdk', 'wic')
data.setVar('IMAGE_CMD:vmdk', ':')
namespace = {'bb': bb}
exec(parsed['get_base_type'], namespace)
image_tasks = next(
    function for function in parsed.getVar('__BBANONFUNCS', False)
    if 'def collect_image_type(' in parsed.getVar(function, False)
)
exec(parsed[image_tasks], namespace)


class TestImageTypeCleanup(unittest.TestCase):
    def generate_image_tasks(self, image_types, deploy_dir='/deploy'):
        d = bb.data.createCopy(data)
        d.setVar('IMAGE_FSTYPES', image_types)
        d.setVar('DEPLOY_DIR_IMAGE', str(deploy_dir))
        d.setVar('IMAGE_FULLNAME', 'image')
        namespace[image_tasks](d)
        return d

    def assert_intermediates(self, image_types, expected):
        d = self.generate_image_tasks(image_types)
        self.assertEqual(
            set(d.getVar('IMAGE_INTERMEDIATE_FILES').split()),
            {'/deploy/image.' + image_type for image_type in expected},
        )

    def test_only_unrequested_types_are_intermediates(self):
        self.assert_intermediates('ova.zst', {'ova', 'vmdk', 'wic'})
        self.assert_intermediates('vmdk ova.zst', {'ova', 'wic'})
        self.assert_intermediates('ova ova.zst vmdk wic', set())

    def test_unrequested_conversion_stages_are_cleaned(self):
        self.assert_intermediates('tar.gz.xz', {'tar', 'tar.gz'})
        self.assert_intermediates('tar.gz tar.gz.xz', {'tar'})

    def test_cleanup_uses_image_type_filename_overrides(self):
        d = bb.data.createCopy(data)
        d.setVar('IMAGE_FSTYPES', 'tar.gz')
        d.setVar('IMAGE_FULLNAME:tar', 'custom-image')
        d.setVar('DEPLOY_DIR_IMAGE:tar', '/custom-deploy')
        namespace[image_tasks](d)
        self.assertEqual(
            d.getVar('IMAGE_INTERMEDIATE_FILES'),
            '/custom-deploy/custom-image.tar',
        )

    def test_cleanup_removes_only_intermediate_files(self):
        with tempfile.TemporaryDirectory() as deploy_dir:
            deploy_dir = Path(deploy_dir)
            for image_type in ('ova', 'wic', 'vmdk', 'ova.zst'):
                (deploy_dir / ('image.' + image_type)).touch()

            d = self.generate_image_tasks('vmdk ova.zst', deploy_dir)
            d.setVar('T', str(deploy_dir / 'temp'))
            exec_func('cleanup_image_intermediates', d)

            self.assertEqual(
                {path.name for path in deploy_dir.glob('image.*')},
                {'image.vmdk', 'image.ova.zst'},
            )


if __name__ == '__main__':
    unittest.main()
