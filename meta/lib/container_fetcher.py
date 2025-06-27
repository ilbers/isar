# This software is a part of ISAR.
# Copyright (c) Siemens AG, 2024
#
# SPDX-License-Identifier: MIT

import oe.path
import os
import tempfile
import json
from   bb.fetch2 import FetchMethod
from   bb.fetch2 import logger
from   bb.fetch2 import MissingChecksumEvent
from   bb.fetch2 import NoChecksumError
from   bb.fetch2 import ChecksumError
from   bb.fetch2 import runfetchcmd

class Container(FetchMethod):
    def supports(self, ud, d):
        return ud.type in ['docker']

    def urldata_init(self, ud, d):
        ud.tag = "latest"
        if "tag" in ud.parm:
            ud.tag = ud.parm["tag"]

        ud.digest = None
        if "digest" in ud.parm:
            ud.digest = ud.parm["digest"]

        ud.arch = d.getVar('PACKAGE_ARCH')
        ud.variant = None
        if ud.arch == "armhf":
            ud.arch = "arm"
            ud.variant = "v7"
        elif ud.arch == "armel":
            ud.arch = "arm"
            ud.variant = "v6"

        ud.container_name = ud.host + (ud.path if ud.path != "/" else "")
        ud.container_src = ud.container_name + \
            ("@" + ud.digest if ud.digest else ":" + ud.tag)
        ud.localname = ud.container_name.replace('/', '.')
        ud.localfile = "container-images/" + ud.arch + "/" + \
            (ud.variant + "/" if ud.variant else "") + ud.localname + \
            "_" + (ud.digest.replace(":", "-") if ud.digest else ud.tag) + \
            ".zst"

    def download(self, ud, d):
        tarball = ud.localfile[:-len('.zst')]
        with tempfile.TemporaryDirectory(dir=d.getVar('DL_DIR')) as tmpdir:
            # If both tag and digest are provided, verify they match
            if ud.digest and "tag" in ud.parm:
                inspect_output = runfetchcmd(f"skopeo inspect docker://{ud.container_name}:{ud.tag}", d, True)
                actual_digest = json.loads(inspect_output)["Digest"]
                if actual_digest != ud.digest:
                    messages = []
                    messages.append(f"Checksum mismatch for {ud.container_name}:{ud.tag}")
                    messages.append("If this change is expected (e.g. you have upgraded " \
                                "to a new version without updating the checksums) " \
                                "then you can use these lines within the recipe:")
                    messages.append(f'SRC_URI = "docker://{ud.container_name};digest={actual_digest};tag={ud.tag}"')
                    messages.append("Otherwise you should retry the download and/or " \
                                "check with upstream to determine if the container image has " \
                                "become corrupted or otherwise unexpectedly modified.")
                    raise ChecksumError("\n".join(messages), ud.url, actual_digest)

            # Take a two steps for downloading into a docker archive because
            # not all source may have the required Docker schema 2 manifest.
            runfetchcmd("skopeo copy --preserve-digests " + \
                f"--override-arch {ud.arch} " + \
                (f"--override-variant {ud.variant} " if ud.variant else "") + \
                f"docker://{ud.container_src} dir:{tmpdir}", d)
            runfetchcmd(f"skopeo copy dir:{tmpdir} " + \
                f"docker-archive:{tarball}:{ud.container_name}:{ud.tag}", d)
        zstd_defaults = d.getVar('ZSTD_DEFAULTS')
        runfetchcmd(f"zstd -f --rm {zstd_defaults} {tarball}", d)

        if ud.digest:
            return

        inspect_output = runfetchcmd(f"skopeo inspect docker://{ud.container_name}:{ud.tag}", d, True)
        digest = json.loads(inspect_output)["Digest"]

        checksum_line = f'SRC_URI = "{ud.url};digest={digest}"'
        strict = d.getVar("BB_STRICT_CHECKSUM") or "0"

        # If strict checking enabled and neither sum defined, raise error
        if strict == "1":
            raise NoChecksumError(checksum_line)

        checksum_event = {"sha256sum": digest}
        bb.event.fire(MissingChecksumEvent(ud.url, **checksum_event), d)

        if strict == "ignore":
            return

        # Log missing digest so user can more easily add it
        logger.warning(
            f"Missing checksum for '{ud.url}', consider using this " \
            f"SRC_URI in the recipe:\n{checksum_line}")

    def unpack(self, ud, rootdir, d):
        image_file = ud.localname + ":" + ud.tag + ".zst"
        oe.path.remove(rootdir + "/" + image_file)
        oe.path.copyhardlink(ud.localpath, rootdir + "/" + image_file)
