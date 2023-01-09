#!/usr/bin/env python3

from cibuilder import CIBuilder
from avocado.utils import process


class ReproBuild(CIBuilder):

    """
    Test reproducible builds by comparing the artifacts

    :avocado: tags=repro-build
    """

    def test_repro_build(self):
        target = self.params.get(
            "build_target", default="mc:qemuamd64-bullseye:isar-image-base"
        )
        source_date_epoch = self.params.get(
            "source_date_epoch", default=self.git_last_commit_timestamp()
        )
        self.init()
        self.build_repro_image(target, source_date_epoch, "image1.tar.gz")
        self.build_repro_image(target, source_date_epoch, "image2.tar.gz")
        self.compare_repro_image("image1.tar.gz", "image2.tar.gz")

    def git_last_commit_timestamp(self):
        return process.run("git log -1 --pretty=%ct").stdout.decode().strip()

    def get_image_path(self, target_name):
        image_dir = "tmp/deploy/images"
        output = process.getoutput(
            f'bitbake -e {target_name} '
            r'| grep "^MACHINE=\|^IMAGE_FULLNAME="'
        )
        env = dict(d.split("=", 1) for d in output.splitlines())
        machine = env["MACHINE"].strip("\"")
        image_name = env["IMAGE_FULLNAME"].strip("\"")
        return f"{image_dir}/{machine}/{image_name}.tar.gz"

    def build_repro_image(
        self, target, source_date_epoch=None, image_name="image.tar.gz"
    ):

        if not source_date_epoch:
            self.error(
             "Reproducible build should configure with source_date_epoch time"
            )

        # clean artifacts before build
        self.clean()

        # Build
        self.log.info("Started Build " + image_name)
        self.configure(source_date_epoch=source_date_epoch)
        self.bitbake(target)

        # copy the artifacts image name with given name
        image_path = self.get_image_path(target)
        self.log.info("Copy image " + image_path + " as " + image_name)
        self.move_in_build_dir(image_path, image_name)

    def clean(self):
        self.delete_from_build_dir("tmp")
        self.delete_from_build_dir("sstate-cache")

    def compare_repro_image(self, image1, image2):
        self.log.info(
            "Compare artifacts image1: " + image1 + ", image2: " + image2
        )
        result = process.run(
            "diffoscope "
            "--text " + self.build_dir + "/diffoscope-output.txt"
            " " + self.build_dir + "/" + image1 +
            " " + self.build_dir + "/" + image2,
            ignore_status=True,
        )
        if result.exit_status > 0:
            self.fail(f"Images {image1} and {image2} are not reproducible")
