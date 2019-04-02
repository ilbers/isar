# This software is a part of ISAR.
# Copyright (c) Siemens AG, 2018

python do_patch() {
    import subprocess

    workdir = d.getVar("WORKDIR", True) + "/"
    src_dir = d.getVar("S", True)

    for src_uri in (d.getVar("SRC_URI", True) or "").split():
        try:
            fetcher = bb.fetch2.Fetch([src_uri], d)

            apply = fetcher.ud[src_uri].parm.get("apply")
            if apply == "no":
                continue

            basename = fetcher.ud[src_uri].basename or ""
            if not (basename.endswith(".patch") or apply == "yes"):
                continue

            patchdir = fetcher.ud[src_uri].parm.get("patchdir") or src_dir
            striplevel = fetcher.ud[src_uri].parm.get("striplevel") or "1"

            cmd = [
                "patch",
                "--no-backup-if-mismatch",
                "-p", striplevel,
                "--directory", patchdir,
                "--input", workdir + basename,
            ]
            bb.note(" ".join(cmd))
            if subprocess.call(cmd) != 0:
                bb.fatal("patching failed")
        except bb.fetch2.BBFetchException as e:
            raise bb.build.FuncFailed(e)
}

do_patch[stamp-extra-info] = "${DISTRO}-${DISTRO_ARCH}"
