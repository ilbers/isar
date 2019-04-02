# This software is a part of ISAR.
# Copyright (c) Siemens AG, 2018-2019

def clean_applied_patches(applied_patches_dir):
    import shutil
    import subprocess

    if not os.path.exists(applied_patches_dir):
        return

    cmds_file = applied_patches_dir + ".patch-commands"
    if os.path.exists(cmds_file):
        with open(cmds_file, "r") as cmds:
            patch_commands = cmds.readlines()
        patch_commands.reverse()
        for patch in patch_commands:
            cmd = patch.split()
            cmd.append("-R")
            cmdline = " ".join(cmd)
            bb.note("Reverting: " + cmdline)
            if subprocess.call(cmd) != 0:
                bb.fatal("patch reverting failed")

    shutil.rmtree(applied_patches_dir)

python do_patch() {
    import shutil
    import subprocess

    workdir = d.getVar("WORKDIR") + "/"
    src_dir = d.getVar("S")

    applied_patches_dirs = []

    for src_uri in (d.getVar("SRC_URI") or "").split():
        try:
            fetcher = bb.fetch2.Fetch([src_uri], d)

            apply = fetcher.ud[src_uri].parm.get("apply")
            if apply == "no":
                continue

            basename = fetcher.ud[src_uri].basename or ""
            if not (basename.endswith(".patch") or apply == "yes"):
                continue

            patchdir = fetcher.ud[src_uri].parm.get("patchdir") or src_dir
            applied_patches_dir = patchdir + "/.applied_patches/"

            if applied_patches_dir not in applied_patches_dirs:
                clean_applied_patches(applied_patches_dir)
                bb.utils.mkdirhier(applied_patches_dir)
                applied_patches_dirs.append(applied_patches_dir)

            cmds = open(applied_patches_dir + ".patch-commands", "a")

            patch_file = applied_patches_dir + basename
            shutil.copyfile(workdir + basename, patch_file)

            striplevel = fetcher.ud[src_uri].parm.get("striplevel") or "1"

            cmd = [
                "patch",
                "--no-backup-if-mismatch",
                "-p", striplevel,
                "--directory", patchdir,
                "--input", patch_file,
            ]
            cmdline = " ".join(cmd)

            bb.note("Applying: " + cmdline)
            if subprocess.call(cmd) != 0:
                bb.fatal("patching failed")

            cmds.write(cmdline + "\n")
            cmds.close()
        except bb.fetch2.BBFetchException as e:
            raise bb.build.FuncFailed(e)
}

do_patch[stamp-extra-info] = "${DISTRO}-${DISTRO_ARCH}"
